import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import PROMPT_COMPLETED_FIELD from '@salesforce/schema/Opportunity.Order_Prompt_Completed__c';

const fields = [STAGE_FIELD, PROMPT_COMPLETED_FIELD];

export default class AutoFlowModal extends LightningElement {
    @api recordId; 
    @api flowApiName; 
    
    @track isModalOpen = false;
    @track isLoading = true;

    @wire(getRecord, { recordId: '$recordId', fields })
    wiredRecord({ error, data }) {
        if (data) {
            const stage = getFieldValue(data, STAGE_FIELD);
            const isCompleted = getFieldValue(data, PROMPT_COMPLETED_FIELD);

            if (stage === 'Closed Won' && isCompleted === false) {
                if (!this.isModalOpen) {
                    this.isLoading = true; 
                }
                this.isModalOpen = true;
            } else {
                this.isModalOpen = false;
            }
        }
    }

    get flowInputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'STARTED') {
            this.isLoading = false;
        }

        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            this.isModalOpen = false;
        }
    }
}