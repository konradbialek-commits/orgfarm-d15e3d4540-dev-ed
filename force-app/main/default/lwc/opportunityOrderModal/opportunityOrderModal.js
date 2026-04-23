import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getProducts from '@salesforce/apex/OrderCreationController.getProducts';
import createOrderWithItems from '@salesforce/apex/OrderCreationController.createOrderWithItems';

const COLUMNS = [
    { label: 'Product Name', fieldName: 'productName' },
    { label: 'Family', fieldName: 'family' },
    { label: 'Unit Price', fieldName: 'unitPrice', type: 'currency' },
    { label: 'Quantity', fieldName: 'quantity', type: 'number', editable: true } 
];

export default class OpportunityOrderModal extends NavigationMixin(LightningElement) {
    @api recordId;
    columns = COLUMNS;
    searchTerm = '';
    
    @track products = [];
    @track selectedProducts = [];
    @track draftValues = [];
    
    isSummaryPage = false;
    isLoading = false;

    @wire(getProducts, { searchTerm: '$searchTerm' })
    wiredProducts({ error, data }) {
        if (data) {
            this.products = data.map(pbe => ({
                Id: pbe.Id,
                productName: pbe.Product2.Name,
                family: pbe.Product2.Family,
                unitPrice: pbe.UnitPrice,
                quantity: 1
            }));
        } else if (error) {
            this.showToast('Error', 'Failed to load products', 'error');
        }
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }

    handleRowSelection(event) {
        this.selectedProducts = event.detail.selectedRows;
    }

    handleQuantityChange(event) {

        let drafts = event.detail.draftValues;
        
        drafts.forEach(draft => {
            let index = this.products.findIndex(p => p.Id === draft.Id);
            if (index !== -1) {
                this.products[index].quantity = draft.quantity;
            }

            let selIndex = this.selectedProducts.findIndex(p => p.Id === draft.Id);
            if(selIndex !== -1) {
                this.selectedProducts[selIndex].quantity = draft.quantity;
            }
        });

        this.draftValues = []; 
    }

    goToSummary() {
        if(this.selectedProducts.length === 0) {
             this.showToast('Hold up!', 'You must select at least one product.', 'warning');
             return;
        }
        this.isSummaryPage = true;
    }

    goBack() {
        this.isSummaryPage = false;
    }

    async handleSubmit() {
        this.isLoading = true;

        let payload = this.selectedProducts.map(p => ({
            pricebookEntryId: p.Id,
            quantity: p.quantity,
            unitPrice: p.unitPrice
        }));

        try {
            const newOrderId = await createOrderWithItems({ 
                oppId: this.recordId, 
                productData: JSON.stringify(payload) 
            });
            
            this.showToast('Success', 'Order Created Successfully!', 'success');

            this.dispatchEvent(new CloseActionScreenEvent());

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: newOrderId,
                    objectApiName: 'Order',
                    actionName: 'view'
                }
            });
        } catch (error) {
            this.showToast('Creation Error', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}