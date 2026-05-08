public class ProductQueueItemAction implements TriggerAction.AfterInsert {
    
    public void afterInsert(List<Product_Sync_Queue__c> newList) {
        if (!System.isQueueable() && !System.isBatch() && !System.isFuture()) {
            System.enqueueJob(new ProductSyncQueueable());
        }
    }
}