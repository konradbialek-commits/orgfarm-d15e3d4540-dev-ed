import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent, FlowNavigationNextEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

export default class OpportunityAutomationPrompt extends LightningElement {
    
    @api isToggled = false; 
    
    // Salesforce automatically passes the available flow actions (Next, Finish, etc.) into this variable
    @api availableActions = []; 

    // --- DYNAMIC BUTTON LOGIC ---
    get buttonLabel() {
        return this.isToggled ? 'Generate Records' : 'Close';
    }

    get buttonVariant() {
        // 'brand' is the standard Salesforce blue button, 'neutral' is the standard white/gray button
        return this.isToggled ? 'brand' : 'neutral';
    }

    get buttonIcon() {
        return this.isToggled ? 'utility:magicwand' : 'utility:close';
    }

    // --- EVENT HANDLERS ---
    handleToggleChange(event) {
        this.isToggled = event.target.checked;
        const attributeChangeEvent = new FlowAttributeChangeEvent('isToggled', this.isToggled);
        this.dispatchEvent(attributeChangeEvent);
    }

    handleNext() {
        // Check if NEXT is an available action in the flow, then fire the event
        if (this.availableActions.find((action) => action === 'NEXT')) {
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
            
        // If this is the very last screen of the flow, the action might be FINISH instead
        } else if (this.availableActions.find((action) => action === 'FINISH')) {
            const navigateFinishEvent = new FlowNavigationFinishEvent();
            this.dispatchEvent(navigateFinishEvent);
        }
    }
}