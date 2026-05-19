import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import getOrderItems from '@salesforce/apex/RefundActionController.getOrderItems';
import processRefund from '@salesforce/apex/RefundActionController.processRefund';

export default class OrderRefundAction extends LightningElement {
    @api recordId;
    @track orderItems = [];
    @track selectedItemIds = [];

    refundType = '';
    description = '';
    isWaiting = false;
    localCaseId;
    subscription = {};

    columns = [
        { label: 'Product', fieldName: 'ProductName' },
        { label: 'Code', fieldName: 'ProductCode' },
        { label: 'Qty', fieldName: 'Quantity', type: 'number' },
        { label: 'Price', fieldName: 'UnitPrice', type: 'currency' }
    ];

    get refundOptions() {
        return [
            { label: 'Full Refund', value: 'Full' },
            { label: 'Partial Refund', value: 'Partial' }
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
            this.showToast('Error', error.body.message, 'error');
        }
    }

    connectedCallback() {
        this.handleSubscribe();

        onError((error) => {
            console.error('EMP API Error: ', JSON.stringify(error));
        });
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
            })
            .catch((error) => {
                this.isWaiting = false;
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleSubscribe() {
        const channelName = '/event/External_Complaint_Response__e';
        subscribe(channelName, -1, (message) => {
            const eventPayload = message.data.payload;

            if (eventPayload.Case_Id__c === this.localCaseId) {
                this.isWaiting = false;
                this.showToast('Success', 'Refund Case created and synchronized successfully.', 'success');
                this.handleCancel();
            }
        }).then((response) => {
            this.subscription = response;
        });
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
