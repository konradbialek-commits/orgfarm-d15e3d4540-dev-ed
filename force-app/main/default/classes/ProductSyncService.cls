public class ProductSyncService {

    public static void enqueueProducts(List<Product2> recordList, String operation) {
        List<Product_Sync_Queue__c> queueItemsToInsert = new List<Product_Sync_Queue__c>();
        
        for (Product2 prod : recordList) {
            if (prod.Is_External__c == true) {
                continue;
            }
            
            String extId = String.isNotBlank(prod.External_Product_Id__c) ? prod.External_Product_Id__c : prod.Id;
            
            ProductPayload payload = new ProductPayload(prod, extId);
            
            Product_Sync_Queue__c queueItem = new Product_Sync_Queue__c(
                Product__c = prod.Id,
                Operation__c = operation,
                Payload__c = JSON.serialize(payload),
                Status__c = Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING,
                Attempt_Count__c = 0,
                Target_Org__c = Util.PRODUCT_SYNC_QUEUE.TARGET_ORG.SZYMON_ORG
            );
            
            queueItemsToInsert.add(queueItem);
        }
        
        if (!queueItemsToInsert.isEmpty()) {
            try {
                insert queueItemsToInsert;
                ErrorLogger.logInfo(
                    'Enqueued ' + queueItemsToInsert.size() + ' products for sync operation: ' + operation, 
                    'ProductSyncService', 
                    'enqueueProducts'
                );
            } catch (Exception e) {
                ErrorLogger.logException(e, 'ProductSyncService', 'enqueueProducts');
            }
        }
    }
}