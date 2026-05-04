import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import getAvailablePricebooks from '@salesforce/apex/OrderCreationController.getAvailablePricebooks';
import getProductFamilies from '@salesforce/apex/OrderCreationController.getProductFamilies';
import getProducts from '@salesforce/apex/OrderCreationController.getProducts';
import createOrderWithItems from '@salesforce/apex/OrderCreationController.createOrderWithItems';
import calculateOrderDiscounts from '@salesforce/apex/DiscountManagerController.calculateOrderDiscounts';

import LBL_BTN_NEXT from '@salesforce/label/c.Btn_Next';
import LBL_BTN_BACK from '@salesforce/label/c.Btn_Back';
import LBL_MSG_SUCCESS from '@salesforce/label/c.Msg_Success';
import LBL_MSG_ERROR from '@salesforce/label/c.Msg_Error';
import LBL_OM_TITLE from '@salesforce/label/c.OM_Title';
import LBL_OM_SEARCH from '@salesforce/label/c.OM_Search';
import LBL_OM_REVIEW from '@salesforce/label/c.OM_Review';
import LBL_OM_SUBTOTAL from '@salesforce/label/c.OM_Subtotal';
import LBL_OM_FINAL_TOTAL from '@salesforce/label/c.OM_Final_Total';
import LBL_OM_SUBMIT from '@salesforce/label/c.OM_Submit';
import DM_Msg_Wait from '@salesforce/label/c.DM_Msg_Wait';
import DM_Err_SelectPricebook from '@salesforce/label/c.DM_Err_SelectPricebook';
import DM_Msg_HoldUp from '@salesforce/label/c.DM_Msg_HoldUp';
import DM_Err_SelectProduct from '@salesforce/label/c.DM_Err_SelectProduct';
import DM_Err_LoadProducts from '@salesforce/label/c.DM_Err_LoadProducts';

export default class OpportunityOrderModal extends NavigationMixin(LightningElement) {
    @api recordId;
    searchTerm = '';
    selectedPricebookId = null;
    selectedFamily = '';
    
    @track pricebookOptions = [];
    @track familyOptions = [];
    @track products = [];
    @track selectedProducts = [];
    @track summaryProducts = [];
    @track discountData = {};
    
    subtotal = 0;
    hasDiscount = false;
    isSummaryPage = false;
    isLoading = false;

    labels = {
        title: LBL_OM_TITLE,
        search: LBL_OM_SEARCH,
        review: LBL_OM_REVIEW,
        subtotal: LBL_OM_SUBTOTAL,
        finalTotal: LBL_OM_FINAL_TOTAL,
        next: LBL_BTN_NEXT,
        back: LBL_BTN_BACK,
        submit: LBL_OM_SUBMIT
    };

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
            this.showToast(LBL_MSG_ERROR, 'Failed to load price books', 'error');
        }
    }

    @wire(getProductFamilies)
    wiredFamilies({ error, data }) {
        if (data) {
            let options = [{ label: 'All Families', value: '' }];
            this.familyOptions = [...options, ...data];
        } else if (error) {
            this.showToast(LBL_MSG_ERROR, 'Failed to load product families', 'error');
        }
    }

    @wire(getProducts, { searchTerm: '$searchTerm', pricebookId: '$selectedPricebookId', productFamily: '$selectedFamily' })
    wiredProducts({ error, data }) {
        if (data) {
            this.products = data.map(pbe => {
                let existingItem = this.selectedProducts.find(sp => sp.Id === pbe.Id);
                return {
                    Id: pbe.Id,
                    productId: pbe.Product2Id, 
                    productName: pbe.Product2.Name,
                    family: pbe.Product2.Family,
                    unitPrice: pbe.UnitPrice,
                    quantity: existingItem ? existingItem.quantity : 1,
                    selected: !!existingItem 
                };
            });
        } else if (error) {
            this.showToast(LBL_MSG_ERROR, DM_Err_LoadProducts, 'error');
        }
    }

    get isSearchDisabled() {
        return !this.selectedPricebookId;
    }

    handlePricebookChange(event) {
        this.selectedPricebookId = event.detail.value;
        this.selectedProducts = [];
        this.searchTerm = '';
        this.selectedFamily = '';
    }

    handleFamilyChange(event) {
        this.selectedFamily = event.detail.value;
    }

    handleSearch(event) {
        this.searchTerm = event.target.value;
    }

    handleRowSelection(event) {
        let prodId = event.target.dataset.id;
        let isChecked = event.target.checked;
        
        let index = this.products.findIndex(p => p.Id === prodId);
        if (index !== -1) {
            this.products[index].selected = isChecked;
        }
        this.syncSelectedProducts();
    }

    handleQuantityChange(event) {
        let prodId = event.target.dataset.id;
        let qty = parseInt(event.target.value, 10);
        
        let index = this.products.findIndex(p => p.Id === prodId);
        if (index !== -1) {
            this.products[index].quantity = isNaN(qty) ? 1 : qty;
        }
        this.syncSelectedProducts();
    }

    syncSelectedProducts() {
        this.products.forEach(p => {
            let selIndex = this.selectedProducts.findIndex(sp => sp.Id === p.Id);
            
            if (p.selected) {
                if (selIndex !== -1) {
                    this.selectedProducts[selIndex].quantity = p.quantity;
                } else {
                    this.selectedProducts.push({ ...p });
                }
            } else {
                if (selIndex !== -1) {
                    this.selectedProducts.splice(selIndex, 1);
                }
            }
        });
    }

    async goToSummary() {
        if (!this.selectedPricebookId) {
            this.showToast(DM_Msg_Wait, DM_Err_SelectPricebook, 'warning');
            return;
        }
        if(this.selectedProducts.length === 0) {
             this.showToast(DM_Msg_HoldUp, DM_Err_SelectProduct, 'warning');
             return;
        }
        
        this.subtotal = this.selectedProducts.reduce((total, prod) => total + (prod.unitPrice * prod.quantity), 0);
        
        let cartPayload = this.selectedProducts.map(p => ({
            pricebookEntryId: p.Id,
            productId: p.productId,
            family: p.family,
            unitPrice: p.unitPrice,
            quantity: p.quantity
        }));
        
        try {
            this.discountData = await calculateOrderDiscounts({ cartPayload: JSON.stringify(cartPayload) });
            this.hasDiscount = this.discountData.discountAmount > 0;
            
            let itemDiscounts = this.discountData.itemDiscounts || {};
            
            this.summaryProducts = this.selectedProducts.map(p => {
                let itemOriginalTotal = p.unitPrice * p.quantity;
                let itemDiscountAmount = itemDiscounts[p.Id] || 0;
                let itemNewTotal = itemOriginalTotal - itemDiscountAmount;
                let itemNewUnitPrice = itemNewTotal / p.quantity;
                
                return {
                    ...p,
                    discountedUnitPrice: itemNewUnitPrice,
                    discountedTotal: itemNewTotal,
                    hasLineDiscount: itemDiscountAmount > 0
                };
            });
            
            this.isSummaryPage = true;
        } catch(error) {
            this.showToast(LBL_MSG_ERROR, error.body ? error.body.message : error.message, 'error');
        }
    }

    goBack() {
        this.isSummaryPage = false;
    }

    async handleSubmit() {
        this.isLoading = true;
        
        let payload = this.summaryProducts.map(p => ({
            pricebookEntryId: p.Id,
            quantity: p.quantity,
            unitPrice: p.discountedUnitPrice
        }));

        try {
            const newOrderId = await createOrderWithItems({ 
                oppId: this.recordId, 
                productData: JSON.stringify(payload),
                pricebookId: this.selectedPricebookId,
                discountAmount: this.discountData.discountAmount,
                appliedDiscounts: this.discountData.appliedDiscounts || '',
                appliedDiscountIds: this.discountData.appliedDiscountIds || []
            });
            
            this.showToast(LBL_MSG_SUCCESS, 'Order Created Successfully!', 'success');
            
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
            this.showToast(LBL_MSG_ERROR, error.body ? error.body.message : error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}