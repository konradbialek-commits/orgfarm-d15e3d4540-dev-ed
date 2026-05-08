@IsTest
private class ProductSyncQueueableTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String body;

        public MockHttpResponseGenerator() {}

        public MockHttpResponseGenerator(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('error') || (this.statusCode != null && this.statusCode != 200)) {
                res.setStatusCode(this.statusCode != null ? this.statusCode : 500);
                res.setBody(this.body != null ? this.body : '{"status":"error"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"status":"success"}');
            }
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Product2 p = new Product2(Name = 'Setup Product', External_Product_Id__c = 'SETUP-001');
        insert p;

        Product_Sync_Queue__c qItemDelete = new Product_Sync_Queue__c(
            Product__c = p.Id,
            Operation__c = 'DELETE',
            Payload__c = '{"externalProductId":"SETUP-001"}',
            Status__c = 'Pending',
            Attempt_Count__c = 0 
        );
        insert qItemDelete;
    }

    @IsTest
    static void testQueueablePostSuccess() {
        delete [SELECT Id FROM Product_Sync_Queue__c];
        
        Product2 p = new Product2(Name = 'Test', External_Product_Id__c = '123');
        insert p;
        Product_Sync_Queue__c q = new Product_Sync_Queue__c(
            Product__c = p.Id, 
            Operation__c = 'INSERT', 
            Status__c = 'Pending', 
            Payload__c = '{"externalProductId":"123"}',
            Attempt_Count__c = 0 
        );
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        Assert.areEqual('Success', [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :q.Id].Status__c);
    }

    @IsTest
    static void testQueueableDeleteSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        Product_Sync_Queue__c updated = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Operation__c = 'DELETE' LIMIT 1];
        Assert.areEqual('Success', updated.Status__c);
    }

    @IsTest
    static void testQueueableFailure() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(500, '{"status":"error"}'));

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        List<Product_Sync_Queue__c> failedItems = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Status__c = 'Failed'];
        Assert.isTrue(failedItems.size() > 0);
    }
}