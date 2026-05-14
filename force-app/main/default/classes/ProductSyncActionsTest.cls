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
    static void testAfterInsertAction() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        insert testProduct;
        
        delete [SELECT Id FROM Product_Sync_Queue__c];

        Test.startTest();
        new ProductAfterInsertSyncAction().afterInsert(new List<Product2>{testProduct});
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [SELECT Operation__c FROM Product_Sync_Queue__c WHERE Product__c = :testProduct.Id AND Operation__c = :Util.PRODUCT_SYNC_QUEUE.OPERATION.INSERT_OPERATION];
        Assert.areEqual(1, queueItems.size());
    }

    @IsTest
    static void testAfterUpdateAction() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        insert testProduct;
        
        delete [SELECT Id FROM Product_Sync_Queue__c];

        Test.startTest();
        new ProductAfterUpdateSyncAction().afterUpdate(new List<Product2>{testProduct}, new List<Product2>{testProduct});
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [SELECT Operation__c FROM Product_Sync_Queue__c WHERE Product__c = :testProduct.Id AND Operation__c = :Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION];
        Assert.areEqual(1, queueItems.size());
    }

    @IsTest
    static void testBeforeDeleteAction() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        insert testProduct;
        
        delete [SELECT Id FROM Product_Sync_Queue__c];

        Test.startTest();
        new ProductBeforeDeleteSyncAction().beforeDelete(new List<Product2>{testProduct});
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [SELECT Operation__c FROM Product_Sync_Queue__c WHERE Product__c = :testProduct.Id AND Operation__c = :Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION];
        Assert.areEqual(1, queueItems.size());
    }

    @IsTest
    static void testProductQueueItemAction() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        insert testProduct;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Product_Sync_Queue__c queueItem = TestDataFactory.createDefaultQueueItem(testProduct.Id);

        Test.startTest();
        insert queueItem;
        Test.stopTest();

        Product_Sync_Queue__c updatedQueueItem = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :queueItem.Id];
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.STATUS.SUCCESS, updatedQueueItem.Status__c);
    }
}