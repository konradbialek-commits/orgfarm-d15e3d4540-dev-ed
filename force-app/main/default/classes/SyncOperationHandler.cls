public interface SyncOperationHandler {
    HttpRequest createRequest(Product_Sync_Queue__c item, Product2 product);
}