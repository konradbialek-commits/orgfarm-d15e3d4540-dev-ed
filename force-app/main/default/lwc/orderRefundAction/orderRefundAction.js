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
import LBL_REFUND_AMOUNT from '@salesforce/label/c.RA_Refund_Amount';
import LBL_REASON from '@salesforce/label/c.RA_Reason';
import LBL_BTN_CANCEL from '@salesforce/label/c.Btn_Cancel';
import LBL_BTN_SUBMIT from '@salesforce/label/c.Btn_Submit';
import LBL_COL_PRODUCT from '@salesforce/label/c.RA_Col_Product';
import LBL_FULL_REFUND from '@salesforce/label/c.RA_Full_Refund';
import LBL_PARTIAL_REFUND from '@salesforce/label/c.RA_Partial_Refund';
import LBL_MSG_SUCCESS from '@salesforce/label/c.Msg_Success';
import LBL_MSG_ERROR from '@salesforce/label/c.Msg_Error';
import GENERIC_ERROR from '@salesforce/label/c.Generic_Error_Message';
import LBL_CONN_ERR_TITLE from '@salesforce/label/c.RA_Connection_Error_Title';
import LBL_CONN_ERR_MSG from '@salesforce/label/c.RA_Connection_Error_Msg';
import LBL_SUB_ERR_TITLE from '@salesforce/label/c.RA_Subscription_Error_Title';
import LBL_SUB_ERR_MSG from '@salesforce/label/c.RA_Subscription_Error_Msg';
import LBL_LOCAL_SUCCESS from '@salesforce/label/c.RA_Local_Success_Msg';
import LBL_TIMEOUT_TITLE from '@salesforce/label/c.RA_Timeout_Title';
import LBL_TIMEOUT_MSG from '@salesforce/label/c.RA_Timeout_Msg';
import LBL_EXT_REJECT_MSG from '@salesforce/label/c.RA_Ext_Reject_Msg';
import LBL_REFUND_FAILED_TITLE from '@salesforce/label/c.RA_Refund_Failed_Title';
import LBL_REQUESTS_SUCCESS from '@salesforce/label/c.RA_Requests_Success_Msg';

export default class OrderRefundAction extends NavigationMixin(LightningElement) {
    @api recordId;
    @track orderItems = [];
    description = '';
    isWaiting = false;

    caseId = null;
    subscription = {};
    timeoutId;
    arrivedEventPayloads = new Map();

    labels = {
        title: LBL_TITLE,
        processing: LBL_PROCESSING,
        submitting: LBL_SUBMITTING,
        product: LBL_COL_PRODUCT,
        refundType: LBL_REFUND_TYPE,
        refundAmount: LBL_REFUND_AMOUNT,
        reason: LBL_REASON,
        cancel: LBL_BTN_CANCEL,
        submit: LBL_BTN_SUBMIT
    };

    get refundOptions() {
        return [
            { label: LBL_FULL_REFUND, value: 'Full' },
            { label: LBL_PARTIAL_REFUND, value: 'Partial' }
        ];
    }

    get isSubmitDisabled() {
        if (!this.description) return true;
        const selectedItems = this.orderItems.filter((item) => item.selected);
        if (selectedItems.length === 0) return true;
        for (let item of selectedItems) {
            if (!item.refundType || !item.refundAmount || parseFloat(item.refundAmount) <= 0) {
                return true;
            }
        }
        return false;
    }

    @wire(getOrderItems, { orderId: '$recordId' })
    wiredItems({ error, data }) {
        if (data) {
            this.orderItems = data.map((row) => ({
                Id: row.Id,
                ProductName: row.Product2.Name,
                ProductCode: row.Product2.ProductCode,
                Quantity: row.Quantity,
                UnitPrice: row.UnitPrice,
                selected: false,
                disabled: true,
                refundType: '',
                refundAmount: null
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
        const itemId = event.target.dataset.id;
        const isChecked = event.target.checked;
        const item = this.orderItems.find((i) => i.Id === itemId);
        if (item) {
            item.selected = isChecked;
            item.disabled = !isChecked;
            if (!isChecked) {
                item.refundType = '';
                item.refundAmount = null;
            } else {
                item.refundAmount = item.UnitPrice * item.Quantity;
                item.refundType = 'Full';
            }
        }
        this.orderItems = [...this.orderItems];
    }

    handleTypeChange(event) {
        const itemId = event.target.dataset.id;
        const item = this.orderItems.find((i) => i.Id === itemId);
        if (item) item.refundType = event.target.value;
        this.orderItems = [...this.orderItems];
    }

    handleAmountChange(event) {
        const itemId = event.target.dataset.id;
        const item = this.orderItems.find((i) => i.Id === itemId);
        if (item) item.refundAmount = event.target.value;
        this.orderItems = [...this.orderItems];
    }

    handleReasonChange(event) {
        this.description = event.target.value;
    }

    handleSubmit() {
        this.isWaiting = true;
        const submitItems = this.orderItems
            .filter((i) => i.selected)
            .map((i) => ({
                orderItemId: i.Id,
                refundType: i.refundType,
                refundAmount: parseFloat(i.refundAmount)
            }));

        processRefund({
            orderId: this.recordId,
            description: this.description,
            refundItemsJSON: JSON.stringify(submitItems)
        })
            .then((result) => {
                this.caseId = result.caseId;
                if (result.hasExternalItems) {
                    this.startProcessingTimeout();
                    this.checkIfFinished();
                } else {
                    this.showToast(LBL_MSG_SUCCESS, LBL_LOCAL_SUCCESS, 'success');
                    this.navigateToRecord(this.caseId);
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
                this.showToast(LBL_TIMEOUT_TITLE, LBL_TIMEOUT_MSG, 'warning');
                this.handleCancel();
            }
        }, 30000);
    }

    clearProcessingTimeout() {
        if (this.timeoutId) clearTimeout(this.timeoutId);
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
        if (this.caseId && this.arrivedEventPayloads.has(this.caseId)) {
            this.isWaiting = false;
            this.clearProcessingTimeout();

            const payload = this.arrivedEventPayloads.get(this.caseId);
            if (payload.Status__c === 'Failed') {
                const errorMsg = payload.Error_Message__c || LBL_EXT_REJECT_MSG;
                this.showToast(LBL_REFUND_FAILED_TITLE, errorMsg, 'error');
            } else {
                this.showToast(LBL_MSG_SUCCESS, LBL_REQUESTS_SUCCESS, 'success');
                this.navigateToRecord(this.caseId);
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
        if (!error) return GENERIC_ERROR;
        if (Array.isArray(error.body)) return error.body.map((e) => e.message).join(', ');
        if (error.body && typeof error.body.message === 'string') return error.body.message;
        if (typeof error.message === 'string') return error.message;
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
