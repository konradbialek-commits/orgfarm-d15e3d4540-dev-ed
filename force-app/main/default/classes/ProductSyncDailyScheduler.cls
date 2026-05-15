public class ProductSyncDailyScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        try {
            List<Product_Sync_Queue__c> failedItems = [
                SELECT Id, Status__c
                FROM Product_Sync_Queue__c
                WHERE Status__c = :Util.PRODUCT_SYNC_QUEUE.STATUS.FAILED AND Attempt_Count__c < 3
                LIMIT 5000
            ];

            if (!failedItems.isEmpty()) {
                for (Product_Sync_Queue__c item : failedItems) {
                    item.Status__c = Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING;
                }
                update failedItems;
            }

            Integer pendingCount = [
                SELECT COUNT()
                FROM Product_Sync_Queue__c
                WHERE Status__c = :Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING
                LIMIT 1
            ];

            if (pendingCount > 0) {
                System.enqueueJob(new ProductSyncQueueable());
            }
        } catch (Exception e) {
            ErrorLogger.logException(e, 'ProductSyncDailyScheduler', 'execute');
        }
    }
}
