import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getAvailablePricebooks from '@salesforce/apex/OrderCreationController.getAvailablePricebooks';
import getProductFamilies from '@salesforce/apex/OrderCreationController.getProductFamilies';
import getProducts from '@salesforce/apex/OrderCreationController.getProducts';
import createOrderWithItems from '@salesforce/apex/OrderCreationController.createOrderWithItems';
import calculateOrderDiscounts from '@salesforce/apex/DiscountManagerController.calculateOrderDiscounts';

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
    selectedPricebookId = null;
    selectedFamily = '';
    
    @track pricebookOptions = [];
    @track familyOptions = [];
    @track products = [];
    @track selectedProducts = [];
    @track draftValues = [];
    @track discountData = {};
    subtotal = 0;
    
    isSummaryPage = false;
    isLoading = false;

    @wire(getAvailablePricebooks)
    wiredPricebooks({ error, data }) {
        if (data) {
            this.pricebookOptions = data.map(pb => ({
                label: pb.Name,
                value: pb.Id
            }));
            
            let defaultPb = data.find(pb => pb.IsStandard);
            if (defaultPb) {
                this.selectedPricebookId = defaultPb.Id;
            } else if (data.length > 0) {
                this.selectedPricebookId = data[0].Id;
            }
        } else if (error) {
            this.showToast('Error', 'Failed to load price books', 'error');
        }
    }

    @wire(getProductFamilies)
    wiredFamilies({ error, data }) {
        if (data) {
            let options = [{ label: 'All Families', value: '' }];
            this.familyOptions = [...options, ...data];
        } else if (error) {
            this.showToast('Error', 'Failed to load product families', 'error');
        }
    }

    @wire(getProducts, { searchTerm: '$searchTerm', pricebookId: '$selectedPricebookId', productFamily: '$selectedFamily' })
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

    get isSearchDisabled() {
        return !this.selectedPricebookId;
    }

    handlePricebookChange(event) {
        this.selectedPricebookId = event.detail.value;
        this.selectedProducts = [];
    }

    handleFamilyChange(event) {
        this.selectedFamily = event.detail.value;
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

    async goToSummary() {
        if (!this.selectedPricebookId) {
            this.showToast('Wait!', 'Please select a Price Book first.', 'warning');
            return;
        }
        if(this.selectedProducts.length === 0) {
             this.showToast('Hold up!', 'You must select at least one product.', 'warning');
             return;
        }
        
        this.subtotal = this.selectedProducts.reduce((total, prod) => total + (prod.unitPrice * prod.quantity), 0);
        
        try {
            this.discountData = await calculateOrderDiscounts({ subtotal: this.subtotal });
            this.isSummaryPage = true;
        } catch(error) {
            this.showToast('Calculation Error', error.body.message, 'error');
        }
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
                productData: JSON.stringify(payload),
                pricebookId: this.selectedPricebookId
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
            this.showToast('Creation Error', error.body ? error.body.message : error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}