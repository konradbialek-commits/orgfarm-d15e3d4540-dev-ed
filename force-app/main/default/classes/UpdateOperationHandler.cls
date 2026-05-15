public class UpdateOperationHandler implements SyncOperationHandler {
    
    public Id getProductIdToRefresh(Product_Sync_Queue__c item) {
        return item.Product__c;
    }

    public void prepareItem(Product_Sync_Queue__c item, Map<Id, Product2> freshProductsMap, List<Product_Sync_Queue__c> itemsToUpdate, List<Product_Sync_Queue__c> itemsToDelete) {
        if (freshProductsMap.containsKey(item.Product__c)) {
            Product2 freshProd = freshProductsMap.get(item.Product__c);
            String extId = String.isNotBlank(freshProd.External_Product_Id__c) ? freshProd.External_Product_Id__c : freshProd.Id;
            
            item.Payload__c = JSON.serialize(new ProductPayload(freshProd, extId));
            itemsToUpdate.add(item);
        } else {
            itemsToDelete.add(item);
        }
    }

    public HttpRequest createRequest(Product_Sync_Queue__c item) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(Util.PRODUCT_SYNC_QUEUE.ENDPOINT_URL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(item.Payload__c);
        return req;
    }
}