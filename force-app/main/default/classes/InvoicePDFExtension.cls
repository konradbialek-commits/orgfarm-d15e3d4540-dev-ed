public with sharing class InvoicePDFExtension {

    public List<OrderItem> lineItems { get; private set; }
    public Decimal subtotal { get; private set; }
    public Decimal taxAmount { get; private set; }
    public Decimal grandTotal { get; private set; }

    public InvoicePDFExtension(ApexPages.StandardController stdController) {
        Invoice__c inv = [SELECT Order__c FROM Invoice__c WHERE Id = :stdController.getId() LIMIT 1];
        
        this.lineItems = [
            SELECT Product2.Name, Quantity, UnitPrice, TotalPrice 
            FROM OrderItem 
            WHERE OrderId = :inv.Order__c
        ];

        this.subtotal = 0;
        for(OrderItem item : this.lineItems) {
            this.subtotal += item.TotalPrice;
        }

        Decimal taxRate = 0.08; 
        this.taxAmount = (this.subtotal * taxRate).setScale(2);

        this.grandTotal = this.subtotal + this.taxAmount;
    }
}