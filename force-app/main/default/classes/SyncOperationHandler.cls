public interface SyncOperationHandler {
    Id getProductIdToRefresh(Product_Sync_Queue__c item);
    void prepareItem(Product_Sync_Queue__c item, Map<Id, Product2> freshProductsMap, List<Product_Sync_Queue__c> itemsToUpdate, List<Product_Sync_Queue__c> itemsToDelete);
    HttpRequest createRequest(Product_Sync_Queue__c item);
}