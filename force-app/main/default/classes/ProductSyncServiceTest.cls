@IsTest
private class ProductSyncServiceTest {

    @IsTest
    static void testEnqueueInsertOperation() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        
        TriggerBase.bypass(Schema.Product2.SObjectType);
        insert testProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);
        
        Test.startTest();
        ProductSyncService.enqueueProducts(new List<Product2>{testProduct}, Util.PRODUCT_SYNC_QUEUE.OPERATION.INSERT_OPERATION);

        List<Product_Sync_Queue__c> queueItems = [
            SELECT Operation__c, Product__c, Target_Org__c, Status__c, Attempt_Count__c 
            FROM Product_Sync_Queue__c 
            WHERE Product__c = :testProduct.Id
        ];

        Assert.areEqual(1, queueItems.size());
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.OPERATION.INSERT_OPERATION, queueItems[0].Operation__c);
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.TARGET_ORG.SZYMON_ORG, queueItems[0].Target_Org__c);
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING, queueItems[0].Status__c);
        Assert.areEqual(0, queueItems[0].Attempt_Count__c);
        
        Test.stopTest();
    }

    @IsTest
    static void testEnqueueUpdateOperation() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        
        TriggerBase.bypass(Schema.Product2.SObjectType);
        insert testProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);
        
        Test.startTest();
        ProductSyncService.enqueueProducts(new List<Product2>{testProduct}, Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION);

        List<Product_Sync_Queue__c> queueItems = [
            SELECT Operation__c 
            FROM Product_Sync_Queue__c 
            WHERE Product__c = :testProduct.Id
        ];

        Assert.areEqual(1, queueItems.size());
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION, queueItems[0].Operation__c);
        
        Test.stopTest();
    }

    @IsTest
    static void testEnqueueDeleteOperation() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        
        TriggerBase.bypass(Schema.Product2.SObjectType);
        insert testProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);
        
        Test.startTest();
        ProductSyncService.enqueueProducts(new List<Product2>{testProduct}, Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION);

        List<Product_Sync_Queue__c> queueItems = [
            SELECT Operation__c 
            FROM Product_Sync_Queue__c 
            WHERE Product__c = :testProduct.Id
        ];

        Assert.areEqual(1, queueItems.size());
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION, queueItems[0].Operation__c);
        
        Test.stopTest();
    }

    @IsTest
    static void testExternalProductsAreIgnored() {
        Product2 externalProduct = TestDataFactory.createDefaultProduct();
        externalProduct.Is_External__c = true;
        
        TriggerBase.bypass(Schema.Product2.SObjectType);
        insert externalProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);
        
        Test.startTest();
        ProductSyncService.enqueueProducts(new List<Product2>{externalProduct}, Util.PRODUCT_SYNC_QUEUE.OPERATION.INSERT_OPERATION);

        List<Product_Sync_Queue__c> queueItems = [
            SELECT Id 
            FROM Product_Sync_Queue__c 
            WHERE Product__c = :externalProduct.Id
        ];

        Assert.isTrue(queueItems.isEmpty());
        
        Test.stopTest();
    }

    @IsTest
    static void testDeduplicateRapidUpdates() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        
        TriggerBase.bypass(Schema.Product2.SObjectType);
        insert testProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);
        
        Test.startTest();
        ProductSyncService.enqueueProducts(new List<Product2>{testProduct}, Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION);
        ProductSyncService.enqueueProducts(new List<Product2>{testProduct}, Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION);
        ProductSyncService.enqueueProducts(new List<Product2>{testProduct}, Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION);
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [
            SELECT Operation__c 
            FROM Product_Sync_Queue__c 
            WHERE Product__c = :testProduct.Id
        ];

        Assert.areEqual(1, queueItems.size());
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION, queueItems[0].Operation__c);
    }

    @IsTest
    static void testOverrideUpdateWithDelete() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        
        TriggerBase.bypass(Schema.Product2.SObjectType);
        insert testProduct;
        TriggerBase.clearBypass(Schema.Product2.SObjectType);
        
        Test.startTest();
        ProductSyncService.enqueueProducts(new List<Product2>{testProduct}, Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION);
        ProductSyncService.enqueueProducts(new List<Product2>{testProduct}, Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION);
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [
            SELECT Operation__c 
            FROM Product_Sync_Queue__c 
            WHERE Product__c = :testProduct.Id
        ];

        Assert.areEqual(1, queueItems.size());
        Assert.areEqual(Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION, queueItems[0].Operation__c);
    }
}