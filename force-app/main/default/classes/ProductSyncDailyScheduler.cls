public class ProductSyncDailyScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        Integer recordsToProcess = [
            SELECT Count() 
            FROM Product_Sync_Queue__c 
            WHERE Status__c IN ('Pending', 'Failed') 
            AND Attempt_Count__c < 3
            LIMIT 1
        ];

        if (recordsToProcess > 0) {
            try {
                System.enqueueJob(new ProductSyncQueueable());
            } catch (Exception e) {
                ErrorLogger.logException(e, 'ProductSyncDailyScheduler', 'execute');
            }
        }
    }
}