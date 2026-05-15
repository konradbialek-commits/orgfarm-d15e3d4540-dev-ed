public class ProductSyncService {
    public static void enqueueProducts(List<Product2> recordList, String operation) {
        Set<Id> productIds = getInternalProductIds(recordList);

        if (productIds.isEmpty()) {
            return;
        }

        Map<Id, Product_Sync_Queue__c> existingItems = getExistingQueueItems(productIds);
        List<Product_Sync_Queue__c> itemsToInsert = new List<Product_Sync_Queue__c>();
        List<Product_Sync_Queue__c> itemsToUpdate = new List<Product_Sync_Queue__c>();

        for (Id prodId : productIds) {
            if (existingItems.containsKey(prodId)) {
                processExistingItem(existingItems.get(prodId), operation, itemsToUpdate);
            } else {
                itemsToInsert.add(createNewQueueItem(prodId, operation));
            }
        }

        commitChanges(itemsToInsert, itemsToUpdate);
    }

    private static Set<Id> getInternalProductIds(List<Product2> recordList) {
        Set<Id> productIds = new Set<Id>();
        for (Product2 prod : recordList) {
            if (prod.Is_External__c != true) {
                productIds.add(prod.Id);
            }
        }
        return productIds;
    }

    private static Map<Id, Product_Sync_Queue__c> getExistingQueueItems(Set<Id> productIds) {
        Map<Id, Product_Sync_Queue__c> existingItems = new Map<Id, Product_Sync_Queue__c>();
        for (Product_Sync_Queue__c item : [
            SELECT Id, Product__c, Operation__c, Status__c, Attempt_Count__c
            FROM Product_Sync_Queue__c
            WHERE
                Product__c IN :productIds
                AND Status__c IN (:Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING, :Util.PRODUCT_SYNC_QUEUE.STATUS.FAILED)
                AND Target_Org__c = :Util.PRODUCT_SYNC_QUEUE.TARGET_ORG.SZYMON_ORG
        ]) {
            existingItems.put(item.Product__c, item);
        }
        return existingItems;
    }

    private static void processExistingItem(
        Product_Sync_Queue__c existingItem,
        String operation,
        List<Product_Sync_Queue__c> itemsToUpdate
    ) {
        Boolean needsUpdate = false;

        if (
            operation == Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION &&
            existingItem.Operation__c != Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION
        ) {
            existingItem.Operation__c = operation;
            needsUpdate = true;
        } else if (
            operation == Util.PRODUCT_SYNC_QUEUE.OPERATION.INSERT_OPERATION &&
            existingItem.Operation__c == Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION
        ) {
            existingItem.Operation__c = Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION;
            needsUpdate = true;
        }

        if (existingItem.Status__c == Util.PRODUCT_SYNC_QUEUE.STATUS.FAILED) {
            existingItem.Status__c = Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING;
            existingItem.Attempt_Count__c = 0;
            needsUpdate = true;
        }

        if (needsUpdate) {
            itemsToUpdate.add(existingItem);
        }
    }

    private static Product_Sync_Queue__c createNewQueueItem(Id prodId, String operation) {
        return new Product_Sync_Queue__c(
            Product__c = prodId,
            Operation__c = operation,
            Status__c = Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING,
            Attempt_Count__c = 0,
            Target_Org__c = Util.PRODUCT_SYNC_QUEUE.TARGET_ORG.SZYMON_ORG
        );
    }

    private static void commitChanges(List<Product_Sync_Queue__c> itemsToInsert, List<Product_Sync_Queue__c> itemsToUpdate) {
        try {
            if (!itemsToInsert.isEmpty()) {
                insert itemsToInsert;
            }
            if (!itemsToUpdate.isEmpty()) {
                update itemsToUpdate;
            }
        } catch (Exception e) {
            ErrorLogger.logException(e, 'ProductSyncService', 'enqueueProducts');
        }
    }
}
