public class DeleteOperationHandler implements SyncOperationHandler {
    public HttpRequest createRequest(Product_Sync_Queue__c item, Product2 product) {
        HttpRequest req = new HttpRequest();
        String extId = String.isNotBlank(product.External_Product_Id__c) ? product.External_Product_Id__c : product.Id;
        
        req.setEndpoint(Util.PRODUCT_SYNC_QUEUE.ENDPOINT_URL + extId);
        req.setMethod('DELETE');
        return req;
    }
}