import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGlobalSettings from '@salesforce/apex/DiscountManagerController.getGlobalSettings';
import saveGlobalSettings from '@salesforce/apex/DiscountManagerController.saveGlobalSettings';
import getDiscounts from '@salesforce/apex/DiscountManagerController.getDiscounts';
import toggleDiscounts from '@salesforce/apex/DiscountManagerController.toggleDiscounts';
import deleteDiscounts from '@salesforce/apex/DiscountManagerController.deleteDiscounts';
import upsertDiscount from '@salesforce/apex/DiscountManagerController.upsertDiscount';

export default class DiscountManager extends LightningElement {
    @track settings = {};
    @track discounts = [];
    selectedRows = [];
    isModalOpen = false;
    @track currentDiscount = {};

    strategyOptions = [
        { label: 'Lowest Discount', value: 'Lowest' },
        { label: 'Highest Discount', value: 'Highest' },
        { label: 'Cumulative', value: 'Cumulative' }
    ];

    typeOptions = [
        { label: 'Percent', value: 'Percent' },
        { label: 'Fixed Amount', value: 'Fixed Amount' }
    ];

    recurrenceOptions = [
        { label: 'None', value: 'None' },
        { label: 'First Day of Month', value: 'First Day of Month' },
        { label: 'Every Monday', value: 'Every Monday' }
    ];

    discountColumns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Active', fieldName: 'Active__c', type: 'boolean' },
        { label: 'Type', fieldName: 'Discount_Type__c' },
        { label: 'Value', fieldName: 'Value__c', type: 'number' },
        { label: 'Recurrence', fieldName: 'Recurrence__c' },
        { label: 'Start Date', fieldName: 'Start_Date__c', type: 'date' },
        { label: 'End Date', fieldName: 'End_Date__c', type: 'date' }
    ];

    connectedCallback() {
        this.loadData();
    }

    loadData() {
        getGlobalSettings().then(result => { this.settings = result; });
        getDiscounts().then(result => { this.discounts = result; });
    }

    handleSettingChange(event) {
        this.settings[event.target.name] = event.target.value;
    }

    saveSettings() {
        saveGlobalSettings({ setting: this.settings })
            .then(() => this.showToast('Success', 'Settings Saved', 'success'))
            .catch(err => this.showToast('Error', err.body.message, 'error'));
    }

    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows.map(row => row.Id);
    }

    activateSelected() { this.toggle(true); }
    deactivateSelected() { this.toggle(false); }

    toggle(isActive) {
        if (!this.selectedRows.length) return;
        toggleDiscounts({ discountIds: this.selectedRows, isActive: isActive })
            .then(() => {
                this.showToast('Success', 'Discounts Updated', 'success');
                this.loadData();
            });
    }

    deleteSelected() {
        if (!this.selectedRows.length) return;
        deleteDiscounts({ discountIds: this.selectedRows })
            .then(() => {
                this.showToast('Success', 'Discounts Deleted', 'success');
                this.loadData();
            })
            .catch(err => this.showToast('Error', err.body.message, 'error'));
    }

    openModal() {
        this.currentDiscount = { sObjectType: 'Discount__c', Active__c: true, Discount_Type__c: 'Percent', Recurrence__c: 'None' };
        this.isModalOpen = true;
    }

    closeModal() { this.isModalOpen = false; }

    handleFormChange(event) {
        const val = event.target.type === 'checkbox' ? event.target.checked : event.target.value;
        this.currentDiscount[event.target.name] = val;
    }

    saveDiscount() {
        upsertDiscount({ discountRecord: this.currentDiscount })
            .then(() => {
                this.showToast('Success', 'Discount Created', 'success');
                this.closeModal();
                this.loadData();
            })
            .catch(err => this.showToast('Error', err.body.message, 'error'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}