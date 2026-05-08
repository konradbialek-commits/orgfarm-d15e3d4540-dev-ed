@IsTest
private class ProductSyncQueueableTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            if (req.getEndpoint().contains('error')) {
                res.setStatusCode(500);
                res.setBody('{"status":"error"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"status":"success"}');
            }
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
        Product2 p = new Product2(Name = 'Test', External_Product_Id__c = '123');
        insert p;
        Product_Sync_Queue__c q = new Product_Sync_Queue__c(Product__c = p.Id, Operation__c = 'INSERT', Status__c = 'Pending', Payload__c = '{}');
        insert q;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        System.enqueueJob(new ProductSyncQueueable());
        Test.stopTest();

        Assert.areEqual('Success', [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :q.Id].Status__c);
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