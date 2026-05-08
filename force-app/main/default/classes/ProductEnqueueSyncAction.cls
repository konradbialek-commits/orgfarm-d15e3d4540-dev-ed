public class ProductEnqueueSyncAction implements TriggerAction.AfterInsert, TriggerAction.AfterUpdate {
    
    public void afterInsert(List<Product2> newList) {
        enqueueProducts(newList, 'INSERT');
    }

    public void afterUpdate(List<Product2> newList, List<Product2> oldList) {
        enqueueProducts(newList, 'UPDATE');
    }

    private void enqueueProducts(List<Product2> newList, String operation) {
        List<Product_Sync_Queue__c> queueItemsToInsert = new List<Product_Sync_Queue__c>();
        
        for (Product2 prod : newList) {
            if (prod.Is_External__c == true) {
                continue;
            }
            
            Map<String, String> payloadMap = new Map<String, String>{
                'externalProductId' => prod.Id,
                'externalOrgId' => UserInfo.getOrganizationId(),
                'name' => prod.Name,
                'description' => prod.Description,
                'productCode' => prod.ProductCode,
                'family' => prod.Family,
                'language' => prod.Language__c
            };
            
            Product_Sync_Queue__c queueItem = new Product_Sync_Queue__c(
                Product__c = prod.Id,
                Operation__c = operation,
                Payload__c = JSON.serialize(payloadMap),
                Status__c = 'Pending',
                Attempt_Count__c = 0,
                Target_Org__c = 'Szymon_Org'
            );
            
            queueItemsToInsert.add(queueItem);
        }
        
        if (!queueItemsToInsert.isEmpty()) {
            try {
                insert queueItemsToInsert;
                ErrorLogger.logInfo(
                    'Enqueued ' + queueItemsToInsert.size() + ' products for sync operation: ' + operation, 
                    'ProductEnqueueSyncAction', 
                    'enqueueProducts'
                );
            } catch (Exception e) {
                ErrorLogger.logException(e, 'ProductEnqueueSyncAction', 'enqueueProducts');
            }
        }
    }
}