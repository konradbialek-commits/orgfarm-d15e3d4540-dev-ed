import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getOrderItems from '@salesforce/apex/RefundActionController.getOrderItems';
import processRefund from '@salesforce/apex/RefundActionController.processRefund';

import LBL_TITLE from '@salesforce/label/c.RA_Title';
import LBL_PROCESSING from '@salesforce/label/c.RA_Processing';
import LBL_SUBMITTING from '@salesforce/label/c.RA_Submitting';
import LBL_REFUND_TYPE from '@salesforce/label/c.RA_Refund_Type';
import LBL_SELECT_TYPE from '@salesforce/label/c.RA_Select_Type';
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
import LBL_SUCCESS_DESC from '@salesforce/label/c.RA_Success_Desc';
import GENERIC_ERROR from '@salesforce/label/c.Generic_Error_Message';

export default class OrderRefundAction extends LightningElement {
    @api recordId;
    @track orderItems = [];
    @track selectedItemIds = [];

    refundType = '';
    description = '';
    isWaiting = false;
    localCaseId;
    subscription = {};
    arrivedEventCaseIds = new Set();

    labels = {
        title: LBL_TITLE,
        processing: LBL_PROCESSING,
        submitting: LBL_SUBMITTING,
        refundType: LBL_REFUND_TYPE,
        selectType: LBL_SELECT_TYPE,
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
        return this.selectedItemIds.length === 0 || !this.refundType || !this.description;
    }

    @wire(getOrderItems, { orderId: '$recordId' })
    wiredItems({ error, data }) {
        if (data) {
            this.orderItems = data.map((row) => {
                return {
                    ...row,
                    ProductName: row.Product2.Name,
                    ProductCode: row.Product2.ProductCode
                };
            });
        } else if (error) {
            this.showToast(LBL_MSG_ERROR, error.body ? error.body.message : GENERIC_ERROR, 'error');
        }
    }

    connectedCallback() {
        this.handleSubscribe();
        onError((error) => {});
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedItemIds = selectedRows.map((row) => row.Id);
    }

    handleChange(event) {
        const field = event.target.name;
        if (field === 'refundType') {
            this.refundType = event.target.value;
        } else if (field === 'description') {
            this.description = event.target.value;
        }
    }

    handleSubmit() {
        this.isWaiting = true;

        processRefund({
            orderId: this.recordId,
            orderItemIds: this.selectedItemIds,
            refundType: this.refundType,
            description: this.description
        })
            .then((result) => {
                this.localCaseId = result;
                this.checkIfFinished();
            })
            .catch((error) => {
                this.isWaiting = false;
                this.showToast(LBL_MSG_ERROR, error.body ? error.body.message : GENERIC_ERROR, 'error');
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubscribe() {
        const channelName = '/event/External_Complaint_Response__e';
        subscribe(channelName, -1, (message) => {
            const eventPayload = message.data.payload;
            this.arrivedEventCaseIds.add(eventPayload.Case_Id__c);
            this.checkIfFinished();
        }).then((response) => {
            this.subscription = response;
        });
    }

    checkIfFinished() {
        if (this.localCaseId && this.arrivedEventCaseIds.has(this.localCaseId)) {
            this.isWaiting = false;
            this.showToast(LBL_MSG_SUCCESS, LBL_SUCCESS_DESC, 'success');
            this.handleCancel();
        }
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription, (response) => {});
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}
