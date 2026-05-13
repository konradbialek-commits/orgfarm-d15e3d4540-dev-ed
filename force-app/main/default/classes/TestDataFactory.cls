@IsTest
public class TestDataFactory {
    
    public static Product2 createProduct(Boolean doInsert, String name, String extId, Boolean isExternal) {
        Product2 p = new Product2(
            Name = name,
            External_Product_Id__c = extId,
            Is_External__c = isExternal,
            IsActive = true
        );
        
        if (doInsert) {
            insert p;
        }
        return p;
    }

    public static Product_Sync_Queue__c createQueueItem(Boolean doInsert, Id productId, String operation, String status, String payload) {
        Product_Sync_Queue__c qItem = new Product_Sync_Queue__c(
            Product__c = productId,
            Operation__c = operation,
            Status__c = status,
            Payload__c = payload,
            Attempt_Count__c = 0
        );
        
        if (doInsert) {
            insert qItem;
        }
        return qItem;
    }
}