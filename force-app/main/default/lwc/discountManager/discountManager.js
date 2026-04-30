import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGlobalSettings from '@salesforce/apex/DiscountManagerController.getGlobalSettings';
import saveGlobalSettings from '@salesforce/apex/DiscountManagerController.saveGlobalSettings';
import getDiscounts from '@salesforce/apex/DiscountManagerController.getDiscounts';
import toggleDiscounts from '@salesforce/apex/DiscountManagerController.toggleDiscounts';
import deleteDiscounts from '@salesforce/apex/DiscountManagerController.deleteDiscounts';
import upsertDiscount from '@salesforce/apex/DiscountManagerController.upsertDiscount';

// Custom Label Imports
import LBL_BTN_SAVE from '@salesforce/label/c.Btn_Save';
import LBL_BTN_CANCEL from '@salesforce/label/c.Btn_Cancel';
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

export default class DiscountManager extends LightningElement {
    @track settings = {};
    @track discounts = [];
    selectedRows = [];
    isModalOpen = false;
    @track currentDiscount = {};

    // Expose labels to HTML
    labels = {
        save: LBL_BTN_SAVE,
        cancel: LBL_BTN_CANCEL,
        title: LBL_DM_TITLE,
        tabGlobal: LBL_DM_TAB_GLOBAL,
        tabDiscounts: LBL_DM_TAB_DISCOUNTS,
        btnNew: LBL_DM_BTN_NEW,
        btnActivate: LBL_DM_BTN_ACTIVATE,
        btnDeactivate: LBL_DM_BTN_DEACTIVATE,
        btnDelete: LBL_DM_BTN_DELETE
    };

    discountColumns = [
        { label: LBL_DM_COL_NAME, fieldName: 'Name' },
        { label: 'Active', fieldName: 'Active__c', type: 'boolean' },
        { label: 'Category', fieldName: 'Discount_Category__c' },
        { label: 'Type', fieldName: 'Discount_Type__c' },
        { label: LBL_DM_COL_VALUE, fieldName: 'Value__c', type: 'number' },
        { label: 'Min Order', fieldName: 'Minimum_Order_Value__c', type: 'currency' },
        { label: 'Recurrence', fieldName: 'Recurrence__c' }
    ];

    get isRecurring() { return this.currentDiscount.Discount_Category__c === 'Recurring'; }
    get isConditional() { return this.currentDiscount.Discount_Category__c === 'Conditional'; }
    get isYearlyCustom() { return this.currentDiscount.Recurrence__c === 'Yearly Custom Date'; }
    get maxDiscountValue() { return this.currentDiscount.Discount_Type__c === 'Percent' ? 100 : null; }

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
        this.currentDiscount = { sObjectType: 'Discount__c', Active__c: true, Discount_Category__c: 'One Time Only', Discount_Type__c: 'Percent', Recurrence__c: 'None' };
        this.isModalOpen = true;
    }

    closeModal() { this.isModalOpen = false; }

    handleFormChange(event) {
        const val = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        this.currentDiscount[event.target.name] = val;
    }

    saveDiscount() {
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) return;

        upsertDiscount({ discountRecord: this.currentDiscount })
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