import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGlobalSettings from '@salesforce/apex/DiscountManagerController.getGlobalSettings';
import saveGlobalSettings from '@salesforce/apex/DiscountManagerController.saveGlobalSettings';
import getDiscounts from '@salesforce/apex/DiscountManagerController.getDiscounts';
import toggleDiscounts from '@salesforce/apex/DiscountManagerController.toggleDiscounts';
import deleteDiscounts from '@salesforce/apex/DiscountManagerController.deleteDiscounts';
import upsertDiscount from '@salesforce/apex/DiscountManagerController.upsertDiscount';
import getAvailableFamilies from '@salesforce/apex/DiscountManagerController.getAvailableFamilies';
import getAvailableProducts from '@salesforce/apex/DiscountManagerController.getAvailableProducts';

import LBL_BTN_SAVE from '@salesforce/label/c.Btn_Save';
import LBL_BTN_CANCEL from '@salesforce/label/c.Btn_Cancel';
import LBL_BTN_NEXT from '@salesforce/label/c.Btn_Next';
import LBL_BTN_BACK from '@salesforce/label/c.Btn_Back';
import LBL_MSG_SUCCESS from '@salesforce/label/c.Msg_Success';
import LBL_MSG_ERROR from '@salesforce/label/c.Msg_Error';
import LBL_DM_TITLE from '@salesforce/label/c.DM_Title';
import LBL_DM_TAB_GLOBAL from '@salesforce/label/c.DM_Tab_Global';
import LBL_DM_TAB_DISCOUNTS from '@salesforce/label/c.DM_Tab_Discounts';
import LBL_DM_BTN_NEW from '@salesforce/label/c.DM_Btn_New';
import LBL_DM_BTN_ACTIVATE from '@salesforce/label/c.DM_Btn_Activate';
import LBL_DM_BTN_DEACTIVATE from '@salesforce/label/c.DM_Btn_Deactivate';
import LBL_DM_BTN_DELETE from '@salesforce/label/c.DM_Btn_Delete';
import LBL_DM_COL_NAME from '@salesforce/label/c.DM_Col_Name';
import LBL_DM_COL_VALUE from '@salesforce/label/c.DM_Col_Value';

import DM_Opt_Lowest from '@salesforce/label/c.DM_Opt_Lowest';
import DM_Opt_Highest from '@salesforce/label/c.DM_Opt_Highest';
import DM_Opt_Cumulative from '@salesforce/label/c.DM_Opt_Cumulative';
import DM_Opt_OneTime from '@salesforce/label/c.DM_Opt_OneTime';
import DM_Opt_Recurring from '@salesforce/label/c.DM_Opt_Recurring';
import DM_Opt_Conditional from '@salesforce/label/c.DM_Opt_Conditional';
import DM_Opt_MinOrder from '@salesforce/label/c.DM_Opt_MinOrder';
import DM_Opt_TwoForOne from '@salesforce/label/c.DM_Opt_TwoForOne';
import DM_Opt_Percent from '@salesforce/label/c.DM_Opt_Percent';
import DM_Opt_Fixed from '@salesforce/label/c.DM_Opt_Fixed';
import DM_Opt_None from '@salesforce/label/c.DM_Opt_None';
import DM_Opt_Daily from '@salesforce/label/c.DM_Opt_Daily';
import DM_Opt_Monday from '@salesforce/label/c.DM_Opt_Monday';
import DM_Opt_Friday from '@salesforce/label/c.DM_Opt_Friday';
import DM_Opt_FirstMonth from '@salesforce/label/c.DM_Opt_FirstMonth';
import DM_Opt_FirstQuarter from '@salesforce/label/c.DM_Opt_FirstQuarter';
import DM_Opt_YearlyCustom from '@salesforce/label/c.DM_Opt_YearlyCustom';

import DM_Lbl_GlobalStrategy from '@salesforce/label/c.DM_Lbl_GlobalStrategy';
import DM_Lbl_MinPriceFloor from '@salesforce/label/c.DM_Lbl_MinPriceFloor';
import DM_Lbl_FloorHelp from '@salesforce/label/c.DM_Lbl_FloorHelp';
import DM_Lbl_ModalTitle from '@salesforce/label/c.DM_Lbl_ModalTitle';
import DM_Lbl_Active from '@salesforce/label/c.DM_Lbl_Active';
import DM_Lbl_Category from '@salesforce/label/c.DM_Lbl_Category';
import DM_Lbl_ConditionType from '@salesforce/label/c.DM_Lbl_ConditionType';
import DM_Lbl_MinOrderReq from '@salesforce/label/c.DM_Lbl_MinOrderReq';
import DM_Lbl_TwoForOneHelp from '@salesforce/label/c.DM_Lbl_TwoForOneHelp';
import DM_Lbl_Recurrence from '@salesforce/label/c.DM_Lbl_Recurrence';
import DM_Lbl_AnnualDate from '@salesforce/label/c.DM_Lbl_AnnualDate';
import DM_Lbl_AnnualHelp from '@salesforce/label/c.DM_Lbl_AnnualHelp';
import DM_Lbl_RecurringHelp from '@salesforce/label/c.DM_Lbl_RecurringHelp';
import DM_Lbl_ValueType from '@salesforce/label/c.DM_Lbl_ValueType';
import DM_Lbl_DiscountValue from '@salesforce/label/c.DM_Lbl_DiscountValue';
import DM_Lbl_StartDate from '@salesforce/label/c.DM_Lbl_StartDate';
import DM_Lbl_EndDate from '@salesforce/label/c.DM_Lbl_EndDate';

import DM_Lbl_TargetType from '@salesforce/label/c.DM_Lbl_TargetType';
import DM_Opt_AllProducts from '@salesforce/label/c.DM_Opt_AllProducts';
import DM_Opt_SpecificFamilies from '@salesforce/label/c.DM_Opt_SpecificFamilies';
import DM_Opt_SpecificProducts from '@salesforce/label/c.DM_Opt_SpecificProducts';
import DM_Lbl_SelectFamilies from '@salesforce/label/c.DM_Lbl_SelectFamilies';
import DM_Lbl_SelectProducts from '@salesforce/label/c.DM_Lbl_SelectProducts';

export default class DiscountManager extends LightningElement {
    @track settings = {};
    @track discounts = [];
    selectedRows = [];
    isModalOpen = false;
    productSearchTerm = '';
    @track currentDiscount = {};
    @track currentStep = 1;
    
    @track familyOptions = [];
    @track productOptions = [];
    selectedFamilies = [];
    selectedProductIds = [];

    labels = {
        save: LBL_BTN_SAVE,
        cancel: LBL_BTN_CANCEL,
        next: LBL_BTN_NEXT,
        back: LBL_BTN_BACK,
        title: LBL_DM_TITLE,
        tabGlobal: LBL_DM_TAB_GLOBAL,
        tabDiscounts: LBL_DM_TAB_DISCOUNTS,
        btnNew: LBL_DM_BTN_NEW,
        btnActivate: LBL_DM_BTN_ACTIVATE,
        btnDeactivate: LBL_DM_BTN_DEACTIVATE,
        btnDelete: LBL_DM_BTN_DELETE,
        lblGlobalStrategy: DM_Lbl_GlobalStrategy,
        lblMinPriceFloor: DM_Lbl_MinPriceFloor,
        lblFloorHelp: DM_Lbl_FloorHelp,
        lblModalTitle: DM_Lbl_ModalTitle,
        lblActive: DM_Lbl_Active,
        lblCategory: DM_Lbl_Category,
        lblConditionType: DM_Lbl_ConditionType,
        lblMinOrderReq: DM_Lbl_MinOrderReq,
        lblTwoForOneHelp: DM_Lbl_TwoForOneHelp,
        lblRecurrence: DM_Lbl_Recurrence,
        lblAnnualDate: DM_Lbl_AnnualDate,
        lblAnnualHelp: DM_Lbl_AnnualHelp,
        lblRecurringHelp: DM_Lbl_RecurringHelp,
        lblValueType: DM_Lbl_ValueType,
        lblDiscountValue: DM_Lbl_DiscountValue,
        lblStartDate: DM_Lbl_StartDate,
        lblEndDate: DM_Lbl_EndDate,
        lblTargetType: DM_Lbl_TargetType,
        lblSelectFamilies: DM_Lbl_SelectFamilies,
        lblSelectProducts: DM_Lbl_SelectProducts
    };

    strategyOptions = [
        { label: DM_Opt_Lowest, value: 'Lowest' },
        { label: DM_Opt_Highest, value: 'Highest' },
        { label: DM_Opt_Cumulative, value: 'Cumulative' }
    ];

    categoryOptions = [
        { label: DM_Opt_OneTime, value: 'One Time Only' },
        { label: DM_Opt_Recurring, value: 'Recurring' },
        { label: DM_Opt_Conditional, value: 'Conditional' }
    ];

    conditionOptions = [
        { label: DM_Opt_MinOrder, value: 'Minimum Order Value' },
        { label: DM_Opt_TwoForOne, value: 'Two For One' }
    ];

    typeOptions = [
        { label: DM_Opt_Percent, value: 'Percent' },
        { label: DM_Opt_Fixed, value: 'Fixed Amount' }
    ];

    recurrenceOptions = [
        { label: DM_Opt_None, value: 'None' },
        { label: DM_Opt_Daily, value: 'Daily' },
        { label: DM_Opt_Monday, value: 'Every Monday' },
        { label: DM_Opt_Friday, value: 'Every Friday' },
        { label: DM_Opt_FirstMonth, value: 'First Day of Month' },
        { label: DM_Opt_FirstQuarter, value: 'First Day of Quarter' },
        { label: DM_Opt_YearlyCustom, value: 'Yearly Custom Date'}
    ];

    targetOptions = [
        { label: DM_Opt_AllProducts, value: 'All Products' },
        { label: DM_Opt_SpecificFamilies, value: 'Specific Families' },
        { label: DM_Opt_SpecificProducts, value: 'Specific Products' }
    ];

    discountColumns = [
        { label: LBL_DM_COL_NAME, fieldName: 'Name' },
        { label: 'Active', fieldName: 'Active__c', type: 'boolean' },
        { label: 'Target', fieldName: 'Target_Type__c' },
        { label: 'Type', fieldName: 'Discount_Type__c' },
        { label: LBL_DM_COL_VALUE, fieldName: 'Value__c', type: 'number' },
        { label: 'Recurrence', fieldName: 'Recurrence__c' }
    ];

    productColumns = [
        { label: 'Product Name', fieldName: 'Name' },
        { label: 'Family', fieldName: 'Family' }
    ];

    @wire(getAvailableFamilies)
    wiredFamilies({ error, data }) {
        if (data) this.familyOptions = data;
    }

    @wire(getAvailableProducts)
    wiredProducts({ error, data }) {
        if (data) this.productOptions = data;
    }

    get isStep1() { return this.currentStep === 1; }
    get isStep2() { return this.currentStep === 2; }
    get isRecurring() { return this.currentDiscount.Discount_Category__c === 'Recurring'; }
    get isConditional() { return this.currentDiscount.Discount_Category__c === 'Conditional'; }
    get isMinimumOrderValue() { return this.currentDiscount.Condition_Type__c === 'Minimum Order Value'; }
    get isTwoForOne() { return this.currentDiscount.Condition_Type__c === 'Two For One'; }
    get isYearlyCustom() { return this.currentDiscount.Recurrence__c === 'Yearly Custom Date'; }
    get maxDiscountValue() { return this.currentDiscount.Discount_Type__c === 'Percent' ? 100 : null; }
    get isTargetFamily() { return this.currentDiscount.Target_Type__c === 'Specific Families'; }
    get isTargetProduct() { return this.currentDiscount.Target_Type__c === 'Specific Products'; }

    connectedCallback() { this.loadData(); }

    loadData() {
        getGlobalSettings().then(result => { this.settings = result; });
        getDiscounts().then(result => { this.discounts = result; });
    }

    handleSettingChange(event) { this.settings[event.target.name] = event.target.value; }

    saveSettings() {
        saveGlobalSettings({ setting: this.settings })
            .then(() => this.showToast(LBL_MSG_SUCCESS, 'Settings Saved', 'success'))
            .catch(err => this.showToast(LBL_MSG_ERROR, err.body.message, 'error'));
    }

    handleRowSelection(event) { this.selectedRows = event.detail.selectedRows.map(row => row.Id); }
    activateSelected() { this.toggle(true); }
    deactivateSelected() { this.toggle(false); }

    toggle(isActive) {
        if (!this.selectedRows.length) return;
        toggleDiscounts({ discountIds: this.selectedRows, isActive: isActive })
            .then(() => {
                this.showToast(LBL_MSG_SUCCESS, 'Discounts Updated', 'success');
                this.loadData();
            });
    }

    deleteSelected() {
        if (!this.selectedRows.length) return;
        deleteDiscounts({ discountIds: this.selectedRows })
            .then(() => {
                this.showToast(LBL_MSG_SUCCESS, 'Discounts Deleted', 'success');
                this.loadData();
            })
            .catch(err => this.showToast(LBL_MSG_ERROR, err.body.message, 'error'));
    }

    openModal() {
        this.currentStep = 1;
        this.selectedFamilies = [];
        this.selectedProductIds = [];
        this.currentDiscount = { 
            sObjectType: 'Discount__c', 
            Active__c: true, 
            Discount_Category__c: 'One Time Only', 
            Discount_Type__c: 'Percent', 
            Recurrence__c: 'None',
            Condition_Type__c: 'Minimum Order Value',
            Target_Type__c: 'All Products'
        };
        this.isModalOpen = true;
    }

    closeModal() { this.isModalOpen = false; }

    handleFormChange(event) {
        const val = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        this.currentDiscount[event.target.name] = val;
    }

    handleFamilySelection(event) {
        this.selectedFamilies = event.detail.value;
    }

    handleProductSearch(event) {
        this.productSearchTerm = event.target.value;
    }

    get filteredProducts() {
        if (!this.productSearchTerm) {
            return this.productOptions;
        }
        const term = this.productSearchTerm.toLowerCase();
        return this.productOptions.filter(p => 
            p.Name.toLowerCase().includes(term) || 
            (p.Family && p.Family.toLowerCase().includes(term))
        );
    }

    handleProductSelection(event) {
        const selectedIds = event.detail.selectedRows.map(row => row.Id);
        const visibleIds = this.filteredProducts.map(row => row.Id);
        const idsToKeep = this.selectedProductIds.filter(id => !visibleIds.includes(id));
        this.selectedProductIds = [...new Set([...idsToKeep, ...selectedIds])];
    }

    nextStep() {
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) return;
        this.currentStep = 2;
    }

    previousStep() {
        this.currentStep = 1;
    }

    saveDiscount() {
        if (this.currentDiscount.Target_Type__c === 'Specific Families' && this.selectedFamilies.length > 0) {
            this.currentDiscount.Eligible_Families__c = this.selectedFamilies.join(';');
        } else {
            this.currentDiscount.Eligible_Families__c = null;
        }

        let productIdsToSave = this.currentDiscount.Target_Type__c === 'Specific Products' ? this.selectedProductIds : [];

        upsertDiscount({ discountRecord: this.currentDiscount, selectedProductIds: productIdsToSave })
            .then(() => {
                this.showToast(LBL_MSG_SUCCESS, 'Discount Created', 'success');
                this.closeModal();
                this.loadData();
            })
            .catch(err => this.showToast(LBL_MSG_ERROR, err.body.message, 'error'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}