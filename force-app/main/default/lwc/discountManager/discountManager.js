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
import getDiscountProducts from '@salesforce/apex/DiscountManagerController.getDiscountProducts';

import { Util } from 'c/discountConstants';

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
import LBL_DM_BTN_ACTIVATE from '@salesforce/label/c.DM_Btn_ACTIVATE';
import LBL_DM_BTN_DEACTIVATE from '@salesforce/label/c.DM_Btn_DEACTIVATE';
import LBL_DM_BTN_DELETE from '@salesforce/label/c.DM_Btn_DELETE';
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
import DM_Opt_VolumeTier from '@salesforce/label/c.DM_Opt_VolumeTier';
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
import DM_Lbl_MinQuantity from '@salesforce/label/c.DM_Lbl_MinQuantity';
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

import DM_Lbl_Name from '@salesforce/label/c.DM_Lbl_Name';
import DM_Lbl_Step from '@salesforce/label/c.DM_Lbl_Step';
import DM_Lbl_Of from '@salesforce/label/c.DM_Lbl_Of';
import DM_Col_Active from '@salesforce/label/c.DM_Col_Active';
import DM_Col_Target from '@salesforce/label/c.DM_Col_Target';
import DM_Col_Type from '@salesforce/label/c.DM_Col_Type';
import DM_Col_Recurrence from '@salesforce/label/c.DM_Col_Recurrence';
import DM_Col_ProductName from '@salesforce/label/c.DM_Col_ProductName';
import DM_Col_Family from '@salesforce/label/c.DM_Col_Family';
import DM_Lbl_SearchProducts from '@salesforce/label/c.DM_Lbl_SearchProducts';
import DM_Btn_Edit from '@salesforce/label/c.DM_Btn_Edit';
import DM_Msg_SettingsSaved from '@salesforce/label/c.DM_Msg_SettingsSaved';
import DM_Msg_DiscountsUpdated from '@salesforce/label/c.DM_Msg_DiscountsUpdated';
import DM_Msg_DiscountsDeleted from '@salesforce/label/c.DM_Msg_DiscountsDeleted';
import DM_Msg_DiscountCreated from '@salesforce/label/c.DM_Msg_DiscountCreated';
import DM_Msg_FailedLoadProducts from '@salesforce/label/c.DM_Msg_FailedLoadProducts';

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
        lblMinQuantity: DM_Lbl_MinQuantity,
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
        lblSelectProducts: DM_Lbl_SelectProducts,
        lblName: DM_Lbl_Name,
        lblStep: DM_Lbl_Step,
        lblOf: DM_Lbl_Of,
        lblSearchProducts: DM_Lbl_SearchProducts
    };

    strategyOptions = [
        { label: DM_Opt_Lowest, value: Util.Strategy.LOWEST },
        { label: DM_Opt_Highest, value: Util.Strategy.HIGHEST },
        { label: DM_Opt_Cumulative, value: Util.Strategy.CUMULATIVE }
    ];

    categoryOptions = [
        { label: DM_Opt_OneTime, value: Util.Discount.CAT_ONETIME },
        { label: DM_Opt_Recurring, value: Util.Discount.CAT_RECURRING },
        { label: DM_Opt_Conditional, value: Util.Discount.CAT_CONDITIONAL }
    ];

    conditionOptions = [
        { label: DM_Opt_MinOrder, value: Util.Discount.COND_MIN_ORDER },
        { label: DM_Opt_TwoForOne, value: Util.Discount.COND_TWO_FOR_ONE },
        { label: DM_Opt_VolumeTier, value: Util.Discount.COND_VOLUME }
    ];

    typeOptions = [
        { label: DM_Opt_Percent, value: Util.Discount.TYPE_PERCENT },
        { label: DM_Opt_Fixed, value: Util.Discount.TYPE_FIXED }
    ];

    recurrenceOptions = [
        { label: DM_Opt_None, value: Util.Discount.REC_NONE },
        { label: DM_Opt_Daily, value: Util.Discount.REC_DAILY },
        { label: DM_Opt_Monday, value: Util.Discount.REC_MONDAY },
        { label: DM_Opt_Friday, value: Util.Discount.REC_FRIDAY },
        { label: DM_Opt_FirstMonth, value: Util.Discount.REC_FIRST_MONTH },
        { label: DM_Opt_FirstQuarter, value: Util.Discount.REC_FIRST_QUARTER },
        { label: DM_Opt_YearlyCustom, value: Util.Discount.REC_YEARLY_CUSTOM }
    ];

    targetOptions = [
        { label: DM_Opt_AllProducts, value: Util.Discount.TARGET_ALL },
        { label: DM_Opt_SpecificFamilies, value: Util.Discount.TARGET_FAMILIES },
        { label: DM_Opt_SpecificProducts, value: Util.Discount.TARGET_PRODUCTS }
    ];

    discountColumns = [
        { label: LBL_DM_COL_NAME, fieldName: Util.Schema.FLD_NAME },
        { label: DM_Col_Active, fieldName: Util.Schema.FLD_ACTIVE, type: 'boolean' },
        { label: DM_Col_Target, fieldName: Util.Schema.FLD_TARGET },
        { label: DM_Col_Type, fieldName: Util.Schema.FLD_TYPE },
        { label: LBL_DM_COL_VALUE, fieldName: Util.Schema.FLD_VALUE, type: 'number' },
        { label: DM_Col_Recurrence, fieldName: Util.Schema.FLD_RECURRENCE },
        { type: 'action', typeAttributes: { rowActions: this.getRowActions.bind(this) } }
    ];

    productColumns = [
        { label: DM_Col_ProductName, fieldName: Util.Schema.FLD_NAME },
        { label: DM_Col_Family, fieldName: Util.Schema.FLD_FAMILY }
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
    get isRecurring() { return this.currentDiscount.Discount_Category__c === Util.Discount.CAT_RECURRING; }
    get isConditional() { return this.currentDiscount.Discount_Category__c === Util.Discount.CAT_CONDITIONAL; }
    get isMinimumOrderValue() { return this.currentDiscount.Condition_Type__c === Util.Discount.COND_MIN_ORDER; }
    get isTwoForOne() { return this.currentDiscount.Condition_Type__c === Util.Discount.COND_TWO_FOR_ONE; }
    get isVolumeTier() { return this.currentDiscount.Condition_Type__c === Util.Discount.COND_VOLUME; }
    get isYearlyCustom() { return this.currentDiscount.Recurrence__c === Util.Discount.REC_YEARLY_CUSTOM; }
    get maxDiscountValue() { return this.currentDiscount.Discount_Type__c === Util.Discount.TYPE_PERCENT ? 100 : null; }
    get isTargetFamily() { return this.currentDiscount.Target_Type__c === Util.Discount.TARGET_FAMILIES; }
    get isTargetProduct() { return this.currentDiscount.Target_Type__c === Util.Discount.TARGET_PRODUCTS; }

    connectedCallback() { this.loadData(); }

    loadData() {
        getGlobalSettings()
            .then(result => { this.settings = result; })
            .catch(err => this.showToast(LBL_MSG_ERROR, err.body ? err.body.message : err.message, 'error'));
            
        getDiscounts()
            .then(result => { this.discounts = result; })
            .catch(err => this.showToast(LBL_MSG_ERROR, err.body ? err.body.message : err.message, 'error'));
    }

    handleSettingChange(event) { this.settings[event.target.name] = event.target.value; }

    saveSettings() {
        saveGlobalSettings({ setting: this.settings })
            .then(() => this.showToast(LBL_MSG_SUCCESS, DM_Msg_SettingsSaved, 'success'))
            .catch(err => this.showToast(LBL_MSG_ERROR, err.body ? err.body.message : err.message, 'error'));
    }

    handleRowSelection(event) { this.selectedRows = event.detail.selectedRows.map(row => row.Id); }
    activateSelected() { this.toggle(true); }
    deactivateSelected() { this.toggle(false); }

    toggle(isActive) {
        if (!this.selectedRows.length) return;
        toggleDiscounts({ discountIds: this.selectedRows, isActive: isActive })
            .then(() => {
                this.showToast(LBL_MSG_SUCCESS, DM_Msg_DiscountsUpdated, 'success');
                this.loadData();
            })
            .catch(err => this.showToast(LBL_MSG_ERROR, err.body ? err.body.message : err.message, 'error'));
    }

    deleteSelected() {
        if (!this.selectedRows.length) return;
        deleteDiscounts({ discountIds: this.selectedRows })
            .then(() => {
                this.showToast(LBL_MSG_SUCCESS, DM_Msg_DiscountsDeleted, 'success');
                this.loadData();
            })
            .catch(err => this.showToast(LBL_MSG_ERROR, err.body ? err.body.message : err.message, 'error'));
    }

    getRowActions(row, doneCallback) {
        const actions = [
            {
                label: DM_Btn_Edit,
                name: Util.Action.EDIT,
                disabled: row.Active__c
            }
        ];
        doneCallback(actions);
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === Util.Action.EDIT) {
            this.openEditModal(row);
        }
    }

    openEditModal(row) {
        this.currentStep = 1;
        this.currentDiscount = { ...row, sObjectType: Util.Schema.OBJ_DISCOUNT };

        if (row.Target_Type__c === Util.Discount.TARGET_FAMILIES && row.Eligible_Families__c) {
            this.selectedFamilies = row.Eligible_Families__c.split(';');
        } else {
            this.selectedFamilies = [];
        }

        if (row.Target_Type__c === Util.Discount.TARGET_PRODUCTS) {
            getDiscountProducts({ discountId: row.Id })
                .then(result => {
                    this.selectedProductIds = result;
                    this.isModalOpen = true;
                })
                .catch(err => {
                    this.showToast(LBL_MSG_ERROR, err.body ? err.body.message : err.message, 'error');
                    this.isModalOpen = true;
                });
        } else {
            this.selectedProductIds = [];
            this.isModalOpen = true;
        }
    }

    openModal() {
        this.currentStep = 1;
        this.selectedFamilies = [];
        this.selectedProductIds = [];
        this.currentDiscount = { 
            sObjectType: Util.Schema.OBJ_DISCOUNT, 
            Active__c: true, 
            Discount_Category__c: Util.Discount.CAT_ONETIME, 
            Discount_Type__c: Util.Discount.TYPE_PERCENT, 
            Recurrence__c: Util.Discount.REC_NONE,
            Condition_Type__c: Util.Discount.COND_MIN_ORDER,
            Target_Type__c: Util.Discount.TARGET_ALL
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
        if (this.isTwoForOne) {
            this.currentDiscount.Discount_Type__c = Util.Discount.TYPE_PERCENT;
            this.currentDiscount.Value__c = 50.0;
        }

        if (this.currentDiscount.Target_Type__c === Util.Discount.TARGET_FAMILIES && this.selectedFamilies.length > 0) {
            this.currentDiscount.Eligible_Families__c = this.selectedFamilies.join(';');
        } else {
            this.currentDiscount.Eligible_Families__c = null;
        }

        let productIdsToSave = this.currentDiscount.Target_Type__c === Util.Discount.TARGET_PRODUCTS ? this.selectedProductIds : [];

        upsertDiscount({ discountRecord: this.currentDiscount, selectedProductIds: productIdsToSave })
            .then(() => {
                this.showToast(LBL_MSG_SUCCESS, DM_Msg_DiscountCreated, 'success');
                this.closeModal();
                this.loadData();
            })
            .catch(err => this.showToast(LBL_MSG_ERROR, err.body ? err.body.message : err.message, 'error'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}