@IsTest
private class ProductSyncActionsTest {

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    @IsTest
    static void testEnqueueSyncActionInsertLocal() {
        Test.startTest();
        Product2 localProduct = new Product2(
            Name = 'Local Action Test',
            Is_External__c = false,
            Language__c = 'en_US'
        );
        insert localProduct;
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [SELECT Id FROM Product_Sync_Queue__c WHERE Product__c = :localProduct.Id];
        Assert.areEqual(1, queueItems.size());
    }

    @IsTest
    static void testProductQueueItemAction() {
        Product2 p = new Product2(Name = 'Queue Trigger Test', Language__c = 'en_US');
        insert p;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Product_Sync_Queue__c qItem = new Product_Sync_Queue__c(
            Product__c = p.Id,
            Status__c = 'Pending',
            Operation__c = 'INSERT',
            Payload__c = '{}',
            Attempt_Count__c = 0
        );

        Test.startTest();
        insert qItem;
        Test.stopTest();

        Product_Sync_Queue__c updated = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :qItem.Id];
        Assert.areEqual('Success', updated.Status__c);
    }
}