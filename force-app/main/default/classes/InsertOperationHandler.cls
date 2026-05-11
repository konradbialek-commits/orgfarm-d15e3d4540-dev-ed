public class InsertOperationHandler implements SyncOperationHandler {
    public HttpRequest createRequest(Product_Sync_Queue__c item) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Util.PRODUCT_SYNC_QUEUE.ENDPOINT_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(item.Payload__c);
        return req;
    }
}