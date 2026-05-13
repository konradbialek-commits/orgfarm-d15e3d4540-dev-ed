@IsTest
public class TestDataFactory {
    
    public static Product2 createProduct(String name, String externalId, Boolean isExternal) {
        return new Product2(
            Name = name,
            External_Product_Id__c = externalId,
            Is_External__c = isExternal,
            ProductCode = 'TEST-CODE',
            Family = 'Other',
            IsActive = true
        );
    }

    public static Product_Sync_Queue__c createQueueItem(Id productId, String operation, String status, String payload) {
        return new Product_Sync_Queue__c(
            Product__c = productId,
            Operation__c = operation,
            Status__c = status,
            Payload__c = payload,
            Attempt_Count__c = 0
        );
    }

    public static String createProductPayloadJson(Product2 product) {
        String extId = String.isNotBlank(product.External_Product_Id__c) ? product.External_Product_Id__c : product.Id;
        ProductPayload payload = new ProductPayload(product, extId);
        return JSON.serialize(payload);
    }
}