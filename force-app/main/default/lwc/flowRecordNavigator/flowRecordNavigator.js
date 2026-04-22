import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class FlowRecordNavigator extends NavigationMixin(LightningElement) {
    @api newRecordId;
    @api successMessage;

    navigateToRecord() {
        if (this.newRecordId) {
            // First, generate the URL for the newly created record
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.newRecordId,
                    actionName: 'view'
                }
            }).then(url => {
                // Then, use standard JavaScript to open that URL in a new browser tab
                window.open(url, '_blank');
            });
        }
    }
}