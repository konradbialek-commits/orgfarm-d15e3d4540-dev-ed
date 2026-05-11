public class DeleteOperationHandler implements SyncOperationHandler {
    public HttpRequest createRequest(Product_Sync_Queue__c item) {
        HttpRequest req = new HttpRequest();
        Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(item.Payload__c);
        String extId = (String) payloadMap.get('externalProductId');
        
        req.setEndpoint(Util.PRODUCT_SYNC_QUEUE.ENDPOINT_URL + extId);
        req.setMethod('DELETE');
        return req;
    }
}