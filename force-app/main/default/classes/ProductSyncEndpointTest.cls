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

    @TestSetup
    static void setupData() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        insert testProduct;
    }

    @IsTest
    static void testAfterInsertAction() {
        Product2 testProduct = [
            SELECT Id, Name, Description, ProductCode, Family, External_Product_Id__c, Is_External__c, Is_Deleted__c
            FROM Product2
            LIMIT 1
        ];
        delete [SELECT Id FROM Product_Sync_Queue__c];

        Test.startTest();
        new ProductAfterInsertSyncAction().afterInsert(new List<Product2>{ testProduct });
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [
            SELECT Operation__c
            FROM Product_Sync_Queue__c
            WHERE Product__c = :testProduct.Id AND Operation__c = :Util.PRODUCT_SYNC_QUEUE.OPERATION.INSERT_OPERATION
        ];
        Assert.areEqual(1, queueItems.size());
    }

    @IsTest
    static void testAfterUpdateActionStandardUpdate() {
        Product2 testProduct = [
            SELECT Id, Name, Description, ProductCode, Family, External_Product_Id__c, Is_External__c, Is_Deleted__c
            FROM Product2
            LIMIT 1
        ];
        delete [SELECT Id FROM Product_Sync_Queue__c];

        Product2 oldProduct = testProduct.clone(true, true, true, true);
        testProduct.Name = 'Changed Name';

        Test.startTest();
        new ProductAfterUpdateSyncAction().afterUpdate(new List<Product2>{ testProduct }, new List<Product2>{ oldProduct });
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [
            SELECT Operation__c
            FROM Product_Sync_Queue__c
            WHERE Product__c = :testProduct.Id AND Operation__c = :Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION
        ];
        Assert.areEqual(1, queueItems.size());
    }

    @IsTest
    static void testAfterUpdateActionSoftDelete() {
        Product2 testProduct = [
            SELECT Id, Name, Description, ProductCode, Family, External_Product_Id__c, Is_External__c, Is_Deleted__c
            FROM Product2
            LIMIT 1
        ];
        delete [SELECT Id FROM Product_Sync_Queue__c];

        Product2 oldProduct = testProduct.clone(true, true, true, true);
        testProduct.Is_Deleted__c = true;

        Test.startTest();
        new ProductAfterUpdateSyncAction().afterUpdate(new List<Product2>{ testProduct }, new List<Product2>{ oldProduct });
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [
            SELECT Operation__c
            FROM Product_Sync_Queue__c
            WHERE Product__c = :testProduct.Id AND Operation__c = :Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION
        ];
        Assert.areEqual(1, queueItems.size());
    }

    @IsTest
    static void testBeforeDeleteActionProductBlocked() {
        Product2 testProduct = [
            SELECT Id, Name, Description, ProductCode, Family, External_Product_Id__c, Is_External__c, Is_Deleted__c
            FROM Product2
            LIMIT 1
        ];
        delete [SELECT Id FROM Product_Sync_Queue__c];

        Test.startTest();
        new ProductBeforeDeleteSyncAction().beforeDelete(new List<Product2>{ testProduct });
        Test.stopTest();

        Assert.isTrue(testProduct.hasErrors());

        List<Product_Sync_Queue__c> queueItems = [SELECT Id FROM Product_Sync_Queue__c WHERE Product__c = :testProduct.Id];
        Assert.isTrue(queueItems.isEmpty());
    }

    @IsTest
    static void testProductQueueItemAction() {
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        delete [SELECT Id FROM Product_Sync_Queue__c];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Product_Sync_Queue__c queueItem = TestDataFactory.createDefaultQueueItem(testProduct.Id);

        Test.startTest();
        insert queueItem;
        Test.stopTest();

        Product_Sync_Queue__c updatedQueueItem = [SELECT Status__c FROM Product_Sync_Queue__c WHERE Id = :queueItem.Id];
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.STATUS.SUCCESS, updatedQueueItem.Status__c);
    }
}
