@IsTest
public class TestDataFactory {
    
    public static Product2 createProduct(String name, String externalId, Boolean isExternal) {
        Product2 product = new Product2(
            Name = name,
            External_Product_Id__c = externalId,
            Is_External__c = isExternal,
            IsActive = true
        );
        
        insert product;
        return product;
    }

    public static Product_Sync_Queue__c createQueueItem(Id productId, String operation, String status, String payload) {
        Product_Sync_Queue__c queueItem = new Product_Sync_Queue__c(
            Product__c = productId,
            Operation__c = operation,
            Status__c = status,
            Payload__c = payload,
            Attempt_Count__c = 0
        );
        
        insert queueItem;
        return queueItem;
    }

    public static String createProductPayloadJson(String externalId, String externalOrgId, String name, String productCode, String productFamily) {
        Map<String, String> payload = new Map<String, String>{
            'externalProductId' => externalId,
            'externalOrgId' => externalOrgId,
            'name' => name,
            'productCode' => productCode,
            'family' => productFamily
        };
        return JSON.serialize(payload);
    }
}