import { LightningElement, api, wire } from 'lwc';
import signAndRegenerateInvoice from '@salesforce/apex/InvoiceManager.signAndRegenerateInvoice';
import isInvoiceSigned from '@salesforce/apex/InvoiceManager.isInvoiceSigned';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class InvoiceSignaturePad extends LightningElement {
    @api recordId; 
    
    isSigned = false;
    isLoading = true;

    isDrawing = false;
    canvas;
    ctx;

    @wire(isInvoiceSigned, { orderId: '$recordId' })
    wiredStatus({ error, data }) {
        if (data !== undefined) {
            this.isSigned = data;
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            console.error('Error checking invoice status:', error);
        }
    }

    renderedCallback() {
        if (!this.canvas && !this.isSigned && !this.isLoading) {
            this.canvas = this.template.querySelector('canvas');
            if (this.canvas) {
                this.ctx = this.canvas.getContext('2d');
                this.canvas.width = this.canvas.offsetWidth;
                this.canvas.height = this.canvas.offsetHeight;
                this.ctx.lineWidth = 2;
                this.ctx.lineCap = 'round';
                this.ctx.strokeStyle = '#000000';
            }
        }
    }

    handleMouseDown(event) { this.startDrawing(event.offsetX, event.offsetY); }
    handleMouseMove(event) { this.draw(event.offsetX, event.offsetY); }
    handleMouseUp() { this.stopDrawing(); }

    handleTouchStart(event) {
        let rect = this.canvas.getBoundingClientRect();
        this.startDrawing(event.touches[0].clientX - rect.left, event.touches[0].clientY - rect.top);
    }
    handleTouchMove(event) {
        event.preventDefault(); 
        let rect = this.canvas.getBoundingClientRect();
        this.draw(event.touches[0].clientX - rect.left, event.touches[0].clientY - rect.top);
    }
    handleTouchEnd() { this.stopDrawing(); }

    startDrawing(x, y) {
        this.isDrawing = true;
        this.ctx.beginPath();
        this.ctx.moveTo(x, y);
    }
    draw(x, y) {
        if (!this.isDrawing) return;
        this.ctx.lineTo(x, y);
        this.ctx.stroke();
    }
    stopDrawing() {
        this.isDrawing = false;
        this.ctx.closePath();
    }

    handleClear() { this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height); }
    handleCancel() { this.dispatchEvent(new CloseActionScreenEvent()); }

    handleSave() {
        const dataURL = this.canvas.toDataURL('image/png');
        
        signAndRegenerateInvoice({ orderId: this.recordId, base64Signature: dataURL })
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'Signature saved! Please refresh the page in a few seconds to view the finalized PDF.',
                    variant: 'success'
                }));
                this.dispatchEvent(new CloseActionScreenEvent());
            })
            .catch(error => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                }));
            });
    }
}