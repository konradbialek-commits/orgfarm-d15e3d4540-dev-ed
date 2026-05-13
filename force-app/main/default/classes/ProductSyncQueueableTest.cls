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
    static void testQueueableInsertSuccessAndPayloadRefresh() {
        Product2 p = TestDataFactory.createProduct(true, 'Old Name', '123', false);
        
        Product_Sync_Queue__c q = TestDataFactory.createQueueItem(
            true, 
            p.Id, 
            Util.PRODUCT_SYNC_QUEUE.OPERATION.INSERT_OPERATION, 
            Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING, 
            '{"name":"Old Name"}'
        );

        p.Name = 'New Fresh Name';
        update p;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"status":"success"}'));

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        Product_Sync_Queue__c updatedQ = [SELECT Status__c, Payload__c FROM Product_Sync_Queue__c WHERE Id = :q.Id];
        
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.STATUS.SUCCESS, updatedQ.Status__c);
        Assert.isTrue(updatedQ.Payload__c.contains('New Fresh Name'));
    }

    @IsTest
    static void testPhantomProductDeletion() {
        Product2 p = TestDataFactory.createProduct(true, 'Phantom Product', '456', false);
        
        Product_Sync_Queue__c q = TestDataFactory.createQueueItem(
            true, 
            p.Id, 
            Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION, 
            Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING, 
            '{"name":"Phantom Product"}'
        );

        delete p;

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        List<Product_Sync_Queue__c> remainingItems = [SELECT Id FROM Product_Sync_Queue__c WHERE Id = :q.Id];
        Assert.isTrue(remainingItems.isEmpty());
    }

    @IsTest
    static void testQueueableDeleteSuccess() {
        Product2 p = TestDataFactory.createProduct(true, 'To Delete', '789', false);
        
        Product_Sync_Queue__c q = TestDataFactory.createQueueItem(
            true, 
            p.Id, 
            Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION, 
            Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING, 
            '{"externalProductId":"789"}'
        );

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"status":"success"}'));

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        Product_Sync_Queue__c updatedQ = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :q.Id];
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.STATUS.SUCCESS, updatedQ.Status__c);
    }

    @IsTest
    static void testQueueableFailure() {
        Product2 p = TestDataFactory.createProduct(true, 'Fail Test', '999', false);
        
        Product_Sync_Queue__c q = TestDataFactory.createQueueItem(
            true, 
            p.Id, 
            Util.PRODUCT_SYNC_QUEUE.OPERATION.INSERT_OPERATION, 
            Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING, 
            '{"externalProductId":"999"}'
        );

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, '{"status":"error"}'));

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        Product_Sync_Queue__c failedQ = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :q.Id];
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.STATUS.FAILED, failedQ.Status__c);
    }

    @IsTest
    static void testQueueableException() {
        Product2 p = TestDataFactory.createProduct(true, 'Exception Test', '000', false);
        
        Product_Sync_Queue__c q = TestDataFactory.createQueueItem(
            true, 
            p.Id, 
            Util.PRODUCT_SYNC_QUEUE.OPERATION.INSERT_OPERATION, 
            Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING, 
            '{"externalProductId":"000"}'
        );

        Test.setMock(HttpCalloutMock.class, new MockHttpExceptionGenerator());

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        Product_Sync_Queue__c exceptionQ = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :q.Id];
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.STATUS.FAILED, exceptionQ.Status__c);
    }
}