@isTest
private class InvoicePDFExtensionTest {
    
    @testSetup
    static void setupTestData() {
        // 1. Create standard Account, Product, and Pricebook
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId, 
            Product2Id = prod.Id, 
            UnitPrice = 100.00, 
            IsActive = true
        );
        insert pbe;
        
        // 2. Create Order and OrderItem
        Order testOrder = new Order(
            AccountId = acc.Id, 
            EffectiveDate = Date.today(), 
            Status = 'Draft', 
            Pricebook2Id = pricebookId
        );
        insert testOrder;
        
        OrderItem oi = new OrderItem(
            OrderId = testOrder.Id, 
            PricebookEntryId = pbe.Id, 
            Quantity = 2, 
            UnitPrice = 100.00
        );
        insert oi; // TotalPrice will be 200.00
        
        // 3. Create Custom Invoice record
        Invoice__c inv = new Invoice__c(
            Order__c = testOrder.Id,
            Status__c = 'Draft'
        );
        insert inv;
    }

    @isTest
    static void testExtensionCalculations() {
        // Retrieve the generated Invoice
        Invoice__c testInvoice = [SELECT Id FROM Invoice__c LIMIT 1];
        
        Test.startTest();
        // Initialize Standard Controller and Extension
        ApexPages.StandardController sc = new ApexPages.StandardController(testInvoice);
        InvoicePDFExtension ext = new InvoicePDFExtension(sc);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, ext.lineItems.size(), 'There should be exactly 1 line item.');
        System.assertEquals(200.00, ext.subtotal, 'Subtotal should be 200.00 (2 * 100).');
        System.assertEquals(16.00, ext.taxAmount, 'Tax should be 16.00 (8% of 200).');
        System.assertEquals(216.00, ext.grandTotal, 'Grand total should be 216.00.');
    }
}