@IsTest
private class ProductSyncQueueableTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public MockHttpResponseGenerator(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(this.statusCode);
            res.setBody(this.body);
            return res;
        }
    }

    private class MockHttpExceptionGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            CalloutException e = (CalloutException)CalloutException.class.newInstance();
            e.setMessage('Simulated Callout Exception');
            throw e;
        }
    }

    @IsTest
    static void testQueueableInsertSuccess() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        
        TriggerBase.bypass(Schema.Product2.SObjectType);
        insert testProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);
        
        Product_Sync_Queue__c queueItem = TestDataFactory.createDefaultQueueItem(testProduct.Id);
        insert queueItem;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"status":"success"}'));

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        Product_Sync_Queue__c updatedQueueItem = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :queueItem.Id];
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.STATUS.SUCCESS, updatedQueueItem.Status__c);
    }

    @IsTest
    static void testPhantomProductDeletion() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        
        TriggerBase.bypass(Schema.Product2.SObjectType);
        insert testProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);
        
        Product_Sync_Queue__c queueItem = TestDataFactory.createDefaultQueueItem(testProduct.Id);
        queueItem.Operation__c = Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION;
        insert queueItem;

        TriggerBase.bypass(Schema.Product2.SObjectType);
        delete testProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        List<Product_Sync_Queue__c> remainingItems = [SELECT Id FROM Product_Sync_Queue__c WHERE Id = :queueItem.Id];
        Assert.isTrue(remainingItems.isEmpty());
    }

    @IsTest
    static void testQueueableDeleteSuccess() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        
        TriggerBase.bypass(Schema.Product2.SObjectType);
        insert testProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);
        
        Product_Sync_Queue__c queueItem = TestDataFactory.createDefaultQueueItem(testProduct.Id);
        queueItem.Operation__c = Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION;
        insert queueItem;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"status":"success"}'));

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        Product_Sync_Queue__c updatedQueueItem = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :queueItem.Id];
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.STATUS.SUCCESS, updatedQueueItem.Status__c);
    }

    @IsTest
    static void testQueueableFailure() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        
        TriggerBase.bypass(Schema.Product2.SObjectType);
        insert testProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);
        
        Product_Sync_Queue__c queueItem = TestDataFactory.createDefaultQueueItem(testProduct.Id);
        insert queueItem;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, '{"status":"error"}'));

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        Product_Sync_Queue__c failedQueueItem = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :queueItem.Id];
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.STATUS.FAILED, failedQueueItem.Status__c);
    }

    @IsTest
    static void testQueueableException() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        
        TriggerBase.bypass(Schema.Product2.SObjectType);
        insert testProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);
        
        Product_Sync_Queue__c queueItem = TestDataFactory.createDefaultQueueItem(testProduct.Id);
        insert queueItem;

        Test.setMock(HttpCalloutMock.class, new MockHttpExceptionGenerator());

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        Product_Sync_Queue__c exceptionQueueItem = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :queueItem.Id];
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.STATUS.FAILED, exceptionQueueItem.Status__c);
    }
}