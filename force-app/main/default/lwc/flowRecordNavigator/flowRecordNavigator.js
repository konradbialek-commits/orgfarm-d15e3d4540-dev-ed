import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class FlowRecordNavigator extends NavigationMixin(LightningElement) {
    @api newRecordId;
    @api successMessage;

    navigateToRecord() {
        if (this.newRecordId) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.newRecordId,
                    actionName: 'view'
                }
            }).then(url => {
                window.open(url, '_blank');
            });
        }
    }
}