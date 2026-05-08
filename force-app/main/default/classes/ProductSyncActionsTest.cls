@IsTest
private class ProductSyncActionsTest {

    @IsTest
    static void testEnqueueSyncActionInsertLocal() {
        Product2 localProduct = new Product2(
            Name = 'Local Action Test',
            Is_External__c = false
        );
        insert localProduct;

        Test.startTest();
        ProductEnqueueSyncAction action = new ProductEnqueueSyncAction();
        action.afterInsert(new List<Product2>{localProduct});
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [SELECT Id, Operation__c FROM Product_Sync_Queue__c WHERE Product__c = :localProduct.Id];
        Assert.areEqual(1, queueItems.size());
        Assert.areEqual('INSERT', queueItems[0].Operation__c);
    }

    @IsTest
    static void testEnqueueSyncActionUpdateLocal() {
        Product2 localProduct = new Product2(
            Name = 'Local Action Test 2',
            Is_External__c = false
        );
        insert localProduct;

        Test.startTest();
        ProductEnqueueSyncAction action = new ProductEnqueueSyncAction();
        action.afterUpdate(new List<Product2>{localProduct}, new List<Product2>{localProduct});
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [SELECT Id, Operation__c FROM Product_Sync_Queue__c WHERE Product__c = :localProduct.Id AND Operation__c = 'UPDATE'];
        Assert.areEqual(1, queueItems.size());
    }

    @IsTest
    static void testEnqueueSyncActionExternalIgnored() {
        Product2 externalProduct = new Product2(
            Name = 'External Action Test',
            Is_External__c = true
        );
        insert externalProduct;

        Test.startTest();
        ProductEnqueueSyncAction action = new ProductEnqueueSyncAction();
        action.afterInsert(new List<Product2>{externalProduct});
        Test.stopTest();

        List<Product_Sync_Queue__c> queueItems = [SELECT Id FROM Product_Sync_Queue__c WHERE Product__c = :externalProduct.Id];
        Assert.areEqual(0, queueItems.size());
    }

    @IsTest
    static void testProductQueueItemAction() {
        Product_Sync_Queue__c qItem = new Product_Sync_Queue__c(
            Status__c = 'Pending',
            Operation__c = 'INSERT'
        );

        Test.startTest();
        ProductQueueItemAction action = new ProductQueueItemAction();
        action.afterInsert(new List<Product_Sync_Queue__c>{qItem});
        Test.stopTest();

        Assert.areEqual(1, Limits.getQueueableJobs());
    }
}