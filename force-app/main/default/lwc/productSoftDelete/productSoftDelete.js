import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class ProductSoftDelete extends LightningElement {
    @api recordId;

    @api invoke() {
        const fields = {};
        fields['Id'] = this.recordId;
        fields['Is_Deleted__c'] = true;

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Product deleted',
                        variant: 'success'
                    })
                );
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }
}