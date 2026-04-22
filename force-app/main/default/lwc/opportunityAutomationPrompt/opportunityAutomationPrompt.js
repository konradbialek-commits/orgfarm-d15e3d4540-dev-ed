import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class OpportunityAutomationPrompt extends LightningElement {
    
    @api isToggled = false; 
    
    @api availableActions = []; 

    get buttonLabel() {
        return this.isToggled ? 'Generate Records' : 'Close';
    }

    get buttonVariant() {
        return this.isToggled ? 'brand' : 'neutral';
    }

    get buttonIcon() {
        return this.isToggled ? 'utility:magicwand' : 'utility:close';
    }

    handleToggleChange(event) {
        this.isToggled = event.target.checked;
        const attributeChangeEvent = new FlowAttributeChangeEvent('isToggled', this.isToggled);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleNext() {
        if (this.availableActions.find((action) => action === 'NEXT')) {
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
            
        } else if (this.availableActions.find((action) => action === 'FINISH')) {
            const navigateFinishEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateFinishEvent);
        }
    }
}