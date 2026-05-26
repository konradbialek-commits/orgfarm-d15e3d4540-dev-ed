import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import processApproval from '@salesforce/apex/RefundApprovalController.processApproval';

import LBL_PROCESSING from '@salesforce/label/c.RA_Processing';
import LBL_SUBMITTING from '@salesforce/label/c.RA_Submitting';
import LBL_BTN_CANCEL from '@salesforce/label/c.Btn_Cancel';
import LBL_BTN_SUBMIT from '@salesforce/label/c.Btn_Submit';
import LBL_MSG_SUCCESS from '@salesforce/label/c.Msg_Success';
import GENERIC_ERROR from '@salesforce/label/c.Generic_Error_Message';

import LBL_AA_TITLE from '@salesforce/label/c.AA_Title';
import LBL_AA_DECISION from '@salesforce/label/c.AA_Decision';
import LBL_AA_COMMENTS from '@salesforce/label/c.AA_Comments';
import LBL_AA_APP_FULL from '@salesforce/label/c.AA_Approve_Full';
import LBL_AA_APP_PARTIAL from '@salesforce/label/c.AA_Approve_Partial';
import LBL_AA_REJECT from '@salesforce/label/c.AA_Reject';
import LBL_AA_SUCCESS_MSG from '@salesforce/label/c.AA_Success_Msg';
import LBL_APP_REFUND_AMT from '@salesforce/label/c.RA_Approved_Refund_Amount';

export default class RefundApprovalAction extends LightningElement {
    @api recordId;

    @track decision = '';
    @track comments = '';
    @track approvedAmount = null;
    @track errorMessage = '';
    @track isLoading = false;

    labels = {
        title: LBL_AA_TITLE,
        processing: LBL_PROCESSING,
        submitting: LBL_SUBMITTING,
        decision: LBL_AA_DECISION,
        comments: LBL_AA_COMMENTS,
        cancel: LBL_BTN_CANCEL,
        submit: LBL_BTN_SUBMIT,
        approvedRefundAmount: LBL_APP_REFUND_AMT
    };

    decisionOptions = [
        { label: LBL_AA_APP_FULL, value: 'Approved Full Refund' },
        { label: LBL_AA_APP_PARTIAL, value: 'Approved Partial Refund' },
        { label: LBL_AA_REJECT, value: 'Rejected' }
    ];

    get isPartialRefund() {
        return this.decision === 'Approved Partial Refund';
    }

    get isSubmitDisabled() {
        if (this.isLoading) return true;
        if (!this.decision) return true;
        if (this.decision === 'Approved Partial Refund' && (!this.approvedAmount || this.approvedAmount <= 0)) {
            return true;
        }
        return false;
    }

    handleChange(event) {
        const field = event.target.name;
        if (field === 'decision') {
            this.decision = event.target.value;
            if (this.decision !== 'Approved Partial Refund') {
                this.approvedAmount = null;
            }
        } else if (field === 'comments') {
            this.comments = event.target.value;
        } else if (field === 'approvedAmount') {
            this.approvedAmount = event.target.value;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    async handleSubmit() {
        this.isLoading = true;
        this.errorMessage = '';

        try {
            await processApproval({
                caseProductId: this.recordId,
                decision: this.decision,
                comments: this.comments,
                approvedAmount: this.approvedAmount ? parseFloat(this.approvedAmount) : null
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: LBL_MSG_SUCCESS,
                    message: LBL_AA_SUCCESS_MSG,
                    variant: 'success'
                })
            );

            this.dispatchEvent(new CloseActionScreenEvent());

            notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        } catch (exception) {
            this.errorMessage = exception.body?.message || GENERIC_ERROR;
        } finally {
            this.isLoading = false;
        }
    }
}
