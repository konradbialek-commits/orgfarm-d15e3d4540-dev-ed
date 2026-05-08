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
            res.setBody(this.body);
            res.setStatusCode(this.statusCode);
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Product2 p = new Product2(Name = 'Local Sync Product', External_Product_Id__c = 'LOCAL-001');
        insert p;

        Product_Sync_Queue__c qItemPost = new Product_Sync_Queue__c(
            Product__c = p.Id,
            Operation__c = 'INSERT',
            Payload__c = '{"name":"Local Sync Product"}',
            Status__c = 'Pending',
            Attempt_Count__c = 0
        );
        insert qItemPost;

        Product_Sync_Queue__c qItemDelete = new Product_Sync_Queue__c(
            Product__c = p.Id,
            Operation__c = 'DELETE',
            Payload__c = '',
            Status__c = 'Pending',
            Attempt_Count__c = 0
        );
        insert qItemDelete;
    }

    @IsTest
    static void testQueueablePostSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"status":"success"}'));

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        List<Product_Sync_Queue__c> updatedItems = [SELECT Status__c, Operation__c FROM Product_Sync_Queue__c WHERE Operation__c = 'INSERT'];
        Assert.areEqual('Success', updatedItems[0].Status__c);
    }

    @IsTest
    static void testQueueableDeleteSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(200, '{"status":"success"}'));

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        List<Product_Sync_Queue__c> updatedItems = [SELECT Status__c, Operation__c FROM Product_Sync_Queue__c WHERE Operation__c = 'DELETE'];
        Assert.areEqual('Success', updatedItems[0].Status__c);
    }

    @IsTest
    static void testQueueableFailure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, '{"status":"error"}'));

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        List<Product_Sync_Queue__c> updatedItems = [SELECT Status__c, Attempt_Count__c, Error_Message__c FROM Product_Sync_Queue__c];
        for(Product_Sync_Queue__c item : updatedItems) {
            Assert.areEqual('Failed', item.Status__c);
            Assert.areEqual(1, item.Attempt_Count__c);
            Assert.isTrue(item.Error_Message__c.contains('HTTP 500'));
        }
    }
}