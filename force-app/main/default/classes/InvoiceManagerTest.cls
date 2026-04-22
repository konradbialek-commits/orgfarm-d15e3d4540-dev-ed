@isTest
private class InvoiceManagerTest {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Order testOrder = new Order(
            AccountId = acc.Id, 
            EffectiveDate = Date.today(), 
            Status = 'Draft'
        );
        insert testOrder;
        
        Invoice__c inv = new Invoice__c(
            Order__c = testOrder.Id,
            Status__c = 'Draft'
        );
        insert inv;
    }

    @isTest
    static void testIsInvoiceSigned() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Invoice__c testInvoice = [SELECT Id, Status__c FROM Invoice__c LIMIT 1];

        System.assertEquals(false, InvoiceManager.isInvoiceSigned(testOrder.Id), 'Invoice should not be signed initially.');
        
        testInvoice.Status__c = 'Signed';
        update testInvoice;
        
        System.assertEquals(true, InvoiceManager.isInvoiceSigned(testOrder.Id), 'Invoice should now be signed.');
    }

    @isTest
    static void testGenerateInvoiceFromFlow() {
        Invoice__c testInvoice = [SELECT Id FROM Invoice__c LIMIT 1];
        
        Test.startTest();
        InvoiceManager.generateInvoiceFromFlow(new List<Id>{ testInvoice.Id });
        Test.stopTest();

        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion WHERE Title LIKE 'Unsigned Invoice%'];
        System.assertEquals(1, cvs.size(), 'A single PDF ContentVersion should have been generated.');
    }

    @isTest
    static void testSignAndRegenerateInvoiceSuccess() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        String mockBase64 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
        
        Test.startTest();
        String result = InvoiceManager.signAndRegenerateInvoice(testOrder.Id, mockBase64);
        Test.stopTest();
        
        System.assertEquals('Success', result, 'The method should return Success.');

        Invoice__c updatedInvoice = [SELECT Status__c FROM Invoice__c LIMIT 1];
        System.assertEquals('Signed', updatedInvoice.Status__c, 'Invoice status should have changed to Signed.');

        List<ContentVersion> cvs = [SELECT Id, Title FROM ContentVersion];
        System.assertEquals(2, cvs.size(), 'Should have created one signature image and one final PDF.');
    }

    @isTest
    static void testSignAndRegenerateInvoiceException() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        Invoice__c testInvoice = [SELECT Id, Status__c FROM Invoice__c LIMIT 1];

        testInvoice.Status__c = 'Signed';
        update testInvoice;
        
        String mockBase64 = 'data:image/png;base64,mockData';
        
        Test.startTest();
        try {
            InvoiceManager.signAndRegenerateInvoice(testOrder.Id, mockBase64);
            System.assert(false, 'An exception should have been thrown.');
        } catch (Exception e) {
            System.assertEquals('System.AuraHandledException', e.getTypeName(), 'Should throw an AuraHandledException.');
        }
        Test.stopTest();
    }
}