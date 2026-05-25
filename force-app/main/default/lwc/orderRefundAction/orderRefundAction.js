import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getOrderItems from '@salesforce/apex/RefundActionController.getOrderItems';
import processRefund from '@salesforce/apex/RefundActionController.processRefund';
import logClientError from '@salesforce/apex/ErrorLogger.logClientError';

import LBL_TITLE from '@salesforce/label/c.RA_Title';
import LBL_PROCESSING from '@salesforce/label/c.RA_Processing';
import LBL_SUBMITTING from '@salesforce/label/c.RA_Submitting';
import LBL_REFUND_TYPE from '@salesforce/label/c.RA_Refund_Type';
import LBL_SELECT_TYPE from '@salesforce/label/c.RA_Select_Type';
import LBL_REFUND_AMOUNT from '@salesforce/label/c.RA_Refund_Amount';
import LBL_REASON from '@salesforce/label/c.RA_Reason';
import LBL_BTN_CANCEL from '@salesforce/label/c.Btn_Cancel';
import LBL_BTN_SUBMIT from '@salesforce/label/c.Btn_Submit';
import LBL_COL_PRODUCT from '@salesforce/label/c.RA_Col_Product';
import LBL_COL_CODE from '@salesforce/label/c.RA_Col_Code';
import LBL_COL_QTY from '@salesforce/label/c.RA_Col_Qty';
import LBL_COL_PRICE from '@salesforce/label/c.RA_Col_Price';
import LBL_FULL_REFUND from '@salesforce/label/c.RA_Full_Refund';
import LBL_PARTIAL_REFUND from '@salesforce/label/c.RA_Partial_Refund';
import LBL_MSG_SUCCESS from '@salesforce/label/c.Msg_Success';
import LBL_MSG_ERROR from '@salesforce/label/c.Msg_Error';
import GENERIC_ERROR from '@salesforce/label/c.Generic_Error_Message';
import LBL_CONN_ERR_TITLE from '@salesforce/label/c.RA_Connection_Error_Title';
import LBL_CONN_ERR_MSG from '@salesforce/label/c.RA_Connection_Error_Msg';
import LBL_SUB_ERR_TITLE from '@salesforce/label/c.RA_Subscription_Error_Title';
import LBL_SUB_ERR_MSG from '@salesforce/label/c.RA_Subscription_Error_Msg';

export default class OrderRefundAction extends NavigationMixin(LightningElement) {
    @api recordId;
    @track orderItems = [];
    @track selectedItemIds = [];

    refundType = '';
    description = '';
    refundAmount = null;
    isWaiting = false;

    localCaseId = null;
    externalCaseId = null;
    correlationId = null;
    subscription = {};
    timeoutId;
    arrivedEventPayloads = new Map();

    labels = {
        title: LBL_TITLE,
        processing: LBL_PROCESSING,
        submitting: LBL_SUBMITTING,
        refundType: LBL_REFUND_TYPE,
        selectType: LBL_SELECT_TYPE,
        refundAmount: LBL_REFUND_AMOUNT,
        reason: LBL_REASON,
        cancel: LBL_BTN_CANCEL,
        submit: LBL_BTN_SUBMIT
    };

    columns = [
        { label: LBL_COL_PRODUCT, fieldName: 'ProductName' },
        { label: LBL_COL_CODE, fieldName: 'ProductCode' },
        { label: LBL_COL_QTY, fieldName: 'Quantity', type: 'number' },
        { label: LBL_COL_PRICE, fieldName: 'UnitPrice', type: 'currency' }
    ];

    get refundOptions() {
        return [
            { label: LBL_FULL_REFUND, value: 'Full' },
            { label: LBL_PARTIAL_REFUND, value: 'Partial' }
        ];
    }

    get isSubmitDisabled() {
        return this.selectedItemIds.length === 0 || !this.refundType || !this.description || !this.refundAmount;
    }

    @wire(getOrderItems, { orderId: '$recordId' })
    wiredItems({ error, data }) {
        if (data) {
            this.orderItems = data.map((row) => ({
                ...row,
                ProductName: row.Product2.Name,
                ProductCode: row.Product2.ProductCode
            }));
        } else if (error) {
            this.logToBackend(error, 'wiredItems');
            this.showToast(LBL_MSG_ERROR, this.extractErrorMessage(error), 'error');
        }
    }

    connectedCallback() {
        this.handleSubscribe();

        onError((error) => {
            this.logToBackend(error, 'empApi_onError');

            if (this.isWaiting) {
                this.isWaiting = false;
                this.clearProcessingTimeout();
                this.showToast(LBL_CONN_ERR_TITLE, LBL_CONN_ERR_MSG, 'error');
            }
        });
    }

    disconnectedCallback() {
        this.clearProcessingTimeout();
        this.handleUnsubscribe();
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedItemIds = selectedRows.map((row) => row.Id);

        let calculatedAmount = 0;
        selectedRows.forEach((row) => {
            calculatedAmount += row.UnitPrice * row.Quantity;
        });

        this.refundAmount = calculatedAmount > 0 ? calculatedAmount : null;
    }

    handleChange(event) {
        const field = event.target.name;
        if (field === 'refundType') this.refundType = event.target.value;
        else if (field === 'description') this.description = event.target.value;
        else if (field === 'refundAmount') this.refundAmount = event.target.value;
    }

    handleSubmit() {
        this.isWaiting = true;

        processRefund({
            orderId: this.recordId,
            orderItemIds: this.selectedItemIds,
            refundType: this.refundType,
            description: this.description,
            refundAmount: parseFloat(this.refundAmount)
        })
            .then((result) => {
                this.localCaseId = result.localCaseId;
                this.externalCaseId = result.externalCaseId;
                this.correlationId = result.correlationId;

                if (this.correlationId) {
                    this.startProcessingTimeout();
                    this.checkIfFinished();
                } else if (this.localCaseId) {
                    this.showToast(LBL_MSG_SUCCESS, 'Local refund request submitted.', 'success');
                    this.navigateToRecord(this.localCaseId);
                    this.handleCancel();
                }
            })
            .catch((error) => {
                this.isWaiting = false;
                this.logToBackend(error, 'handleSubmit');
                this.showToast(LBL_MSG_ERROR, this.extractErrorMessage(error), 'error');
            });
    }

    startProcessingTimeout() {
        this.clearProcessingTimeout();
        this.timeoutId = setTimeout(() => {
            if (this.isWaiting) {
                this.isWaiting = false;
                this.showToast(
                    'Request Timed Out',
                    'The external system took too long to respond. The request may still be processing.',
                    'warning'
                );
                this.handleCancel();
            }
        }, 30000);
    }

    clearProcessingTimeout() {
        if (this.timeoutId) {
            clearTimeout(this.timeoutId);
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubscribe() {
        const channelName = '/event/External_Complaint_Response__e';
        subscribe(channelName, -1, (message) => {
            try {
                const eventPayload = message.data.payload;
                this.arrivedEventPayloads.set(eventPayload.Case_Id__c, eventPayload);
                this.checkIfFinished();
            } catch (error) {
                this.logToBackend(error, 'handleSubscribe_messageCallback');
            }
        })
            .then((response) => {
                this.subscription = response;
            })
            .catch((error) => {
                this.logToBackend(error, 'handleSubscribe');
                this.showToast(LBL_SUB_ERR_TITLE, LBL_SUB_ERR_MSG, 'warning');
            });
    }

    checkIfFinished() {
        if (this.correlationId && this.arrivedEventPayloads.has(this.correlationId)) {
            this.isWaiting = false;
            this.clearProcessingTimeout();

            const payload = this.arrivedEventPayloads.get(this.correlationId);

            if (payload.Status__c === 'Failed') {
                const errorMsg = payload.Error_Message__c || 'The external system rejected the request due to an error.';
                this.showToast('Refund Failed', errorMsg, 'error');
            } else {
                this.showToast(LBL_MSG_SUCCESS, 'Requests processed successfully.', 'success');
                const targetRecordId = this.localCaseId || this.externalCaseId;
                if (targetRecordId) {
                    this.navigateToRecord(targetRecordId);
                }
                this.handleCancel();
            }
        }
    }

    handleUnsubscribe() {
        if (this.subscription && this.subscription.id) {
            unsubscribe(this.subscription, () => {}).catch((error) => {
                this.logToBackend(error, 'handleUnsubscribe');
            });
        }
    }

    navigateToRecord(recId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: recId, actionName: 'view' }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    extractErrorMessage(error) {
        if (!error) {
            return GENERIC_ERROR;
        }

        if (Array.isArray(error.body)) {
            return error.body.map((e) => e.message).join(', ');
        }

        if (error.body && typeof error.body.message === 'string') {
            return error.body.message;
        }

        if (typeof error.message === 'string') {
            return error.message;
        }

        return error.statusText || GENERIC_ERROR;
    }

    logToBackend(error, methodName) {
        let msg = this.extractErrorMessage(error);
        let stack = error.stack ? error.stack : JSON.stringify(error);

        logClientError({
            errorMessage: msg,
            stackTrace: stack,
            componentName: 'orderRefundAction',
            methodName: methodName
        }).catch((err) => {
            console.error('Failed to log error to backend: ', err);
        });
    }
}
