import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import getCaseProducts from '@salesforce/apex/RefundApprovalController.getCaseProducts';
import processBulkApproval from '@salesforce/apex/RefundApprovalController.processBulkApproval';
import rejectCase from '@salesforce/apex/RefundApprovalController.rejectCase';

import LBL_PROCESSING from '@salesforce/label/c.RA_Processing';
import LBL_BTN_CANCEL from '@salesforce/label/c.Btn_Cancel';
import LBL_BTN_SUBMIT from '@salesforce/label/c.Btn_Submit';
import LBL_MSG_SUCCESS from '@salesforce/label/c.Msg_Success';
import GENERIC_ERROR from '@salesforce/label/c.Generic_Error_Message';

import LBL_AA_TITLE from '@salesforce/label/c.AA_Title';
import LBL_AA_DECISION from '@salesforce/label/c.AA_Decision';
import LBL_AA_COMMENTS from '@salesforce/label/c.AA_Comments';
import LBL_AA_APP_FULL from '@salesforce/label/c.AA_Approve_Full';
import LBL_AA_APP_PARTIAL from '@salesforce/label/c.AA_Approve_Partial';
import LBL_AA_SUCCESS_MSG from '@salesforce/label/c.AA_Success_Msg';
import LBL_APP_REFUND_AMT from '@salesforce/label/c.RA_Approved_Refund_Amount';

export default class RefundApprovalAction extends LightningElement {
    @api recordId;

    @track lineItems = [];
    @track comments = '';
    @track errorMessage = '';
    @track isLoading = true;

    labels = {
        title: LBL_AA_TITLE,
        processing: LBL_PROCESSING,
        decision: LBL_AA_DECISION,
        comments: LBL_AA_COMMENTS,
        cancel: LBL_BTN_CANCEL,
        submit: LBL_BTN_SUBMIT,
        approvedAmount: LBL_APP_REFUND_AMT,
        product: 'Product',
        requested: 'Requested'
    };

    decisionOptions = [
        { label: LBL_AA_APP_FULL, value: 'Approved Full Refund' },
        { label: LBL_AA_APP_PARTIAL, value: 'Approved Partial Refund' },
        { label: 'Pending', value: 'Pending' }
    ];

    @wire(getCaseProducts, { caseId: '$recordId' })
    wiredProducts({ error, data }) {
        if (data) {
            this.lineItems = data.map((item) => {
                // Force external items to be read-only so local managers can't edit Szymon's stuff
                let isReadOnly = item.Refund_Status__c !== 'Pending' || item.Is_External__c;
                return {
                    ...item,
                    isReadOnly: isReadOnly,
                    disableAmount: isReadOnly || item.Refund_Status__c !== 'Approved Partial Refund',
                    approvedAmount: item.Refund_Status__c === 'Approved Partial Refund' ? item.Refund_Amount__c : null
                };
            });
            this.isLoading = false;
        } else if (error) {
            this.errorMessage = error.body?.message || GENERIC_ERROR;
            this.isLoading = false;
        }
    }

    get isSubmitDisabled() {
        if (this.isLoading) return true;
        if (this.lineItems.length === 0) return true;

        for (let item of this.lineItems) {
            // Ignore external items; only block submission if LOCAL items are left pending
            if (!item.Is_External__c && item.Refund_Status__c === 'Pending') {
                return true;
            }
            if (
                !item.Is_External__c &&
                item.Refund_Status__c === 'Approved Partial Refund' &&
                (!item.approvedAmount || parseFloat(item.approvedAmount) <= 0)
            ) {
                return true;
            }
        }
        return false;
    }

    handleDecisionChange(event) {
        const itemId = event.target.dataset.id;
        const newStatus = event.target.value;
        const item = this.lineItems.find((i) => i.Id === itemId);

        if (item) {
            item.Refund_Status__c = newStatus;
            item.disableAmount = newStatus !== 'Approved Partial Refund';
            if (newStatus === 'Approved Full Refund') {
                item.approvedAmount = item.Refund_Amount__c;
            } else if (newStatus !== 'Approved Partial Refund') {
                item.approvedAmount = null;
            }
            this.lineItems = [...this.lineItems];
        }
    }

    handleAmountChange(event) {
        const itemId = event.target.dataset.id;
        const item = this.lineItems.find((i) => i.Id === itemId);
        if (item) {
            item.approvedAmount = event.target.value;
            this.lineItems = [...this.lineItems];
        }
    }

    handleCommentsChange(event) {
        this.comments = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleReject() {
        this.isLoading = true;
        this.errorMessage = '';

        try {
            await rejectCase({
                caseId: this.recordId,
                comments: this.comments
            });

            this.dispatchEvent(
                new ShowToastEvent({ title: LBL_MSG_SUCCESS, message: 'Your local items have been rejected.', variant: 'success' })
            );
            this.dispatchEvent(new CloseActionScreenEvent());
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        } catch (exception) {
            this.errorMessage = exception.body?.message || GENERIC_ERROR;
            this.isLoading = false;
        }
    }

    async handleSubmit() {
        this.isLoading = true;
        this.errorMessage = '';

        const updates = this.lineItems
            .filter((item) => !item.isReadOnly && !item.Is_External__c)
            .map((item) => ({
                id: item.Id,
                status: item.Refund_Status__c,
                approvedAmount: item.approvedAmount ? parseFloat(item.approvedAmount) : null
            }));

        if (updates.length === 0) {
            this.handleCancel();
            return;
        }

        try {
            await processBulkApproval({
                caseId: this.recordId,
                comments: this.comments,
                lineItemsJSON: JSON.stringify(updates)
            });

            this.dispatchEvent(new ShowToastEvent({ title: LBL_MSG_SUCCESS, message: LBL_AA_SUCCESS_MSG, variant: 'success' }));
            this.dispatchEvent(new CloseActionScreenEvent());
            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        } catch (exception) {
            this.errorMessage = exception.body?.message || GENERIC_ERROR;
            this.isLoading = false;
        }
    }
}
