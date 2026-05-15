public abstract class BaseSaveOperationHandler implements SyncOperationHandler {
    public HttpRequest createRequest(Product_Sync_Queue__c item, Product2 product) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Util.PRODUCT_SYNC_QUEUE.ENDPOINT_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        String extId = String.isNotBlank(product.External_Product_Id__c) ? product.External_Product_Id__c : product.Id;
        req.setBody(JSON.serialize(new ProductPayload(product, extId)));
        
        return req;
    }
}