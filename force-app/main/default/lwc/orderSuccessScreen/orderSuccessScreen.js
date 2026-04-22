import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class OrderSuccessScreen extends NavigationMixin(LightningElement) {
    
    @api orderId;
    @api contractId;
    @api availableActions = []; 

    navigateToOrder() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.orderId,
                objectApiName: 'Order',
                actionName: 'view'
            }
        }).then((url) => {
            window.open(url, '_blank');
        });
    }

    navigateToContract() {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.contractId,
                objectApiName: 'Contract',
                actionName: 'view'
            }
        }).then((url) => {
            window.open(url, '_blank');
        });
    }
}