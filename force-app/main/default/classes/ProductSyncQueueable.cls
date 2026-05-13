public class ProductSyncQueueable implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        List<Product_Sync_Queue__c> queueItems = getPendingQueueItems();

        if (queueItems.isEmpty()) {
            return;
        }

        List<Product_Sync_Queue__c> itemsToUpdate = processQueueItems(queueItems);
        
        if (!itemsToUpdate.isEmpty()) {
            update itemsToUpdate;
        }
        
        enqueueNextJobIfNeeded();
    }

    private List<Product_Sync_Queue__c> getPendingQueueItems() {
        return [
            SELECT Id, Operation__c, Payload__c, Attempt_Count__c, Product__c, Product__r.External_Product_Id__c
            FROM Product_Sync_Queue__c
            WHERE Status__c IN ('Pending', 'Failed')
            AND Attempt_Count__c < 3
            LIMIT 50
        ];
    }

    private List<Product_Sync_Queue__c> processQueueItems(List<Product_Sync_Queue__c> queueItems) {
        Set<Id> productIdsToRefresh = new Set<Id>();
        for (Product_Sync_Queue__c item : queueItems) {
            if (item.Operation__c != Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION) {
                productIdsToRefresh.add(item.Product__c);
            }
        }

        Map<Id, Product2> freshProductsMap = new Map<Id, Product2>([
            SELECT Id, Name, Description, ProductCode, Family, External_Product_Id__c 
            FROM Product2 
            WHERE Id IN :productIdsToRefresh
        ]);

        Http http = new Http();
        List<Product_Sync_Queue__c> itemsToUpdate = new List<Product_Sync_Queue__c>();
        List<Product_Sync_Queue__c> itemsToDelete = new List<Product_Sync_Queue__c>();

        for (Product_Sync_Queue__c item : queueItems) {
            if (item.Operation__c != Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION) {
                if (freshProductsMap.containsKey(item.Product__c)) {
                    Product2 freshProd = freshProductsMap.get(item.Product__c);
                    String extId = String.isNotBlank(freshProd.External_Product_Id__c) ? freshProd.External_Product_Id__c : freshProd.Id;
                    
                    ProductPayload freshPayload = new ProductPayload(freshProd, extId);
                    item.Payload__c = JSON.serialize(freshPayload);
                    itemsToUpdate.add(item);
                } else {
                    itemsToDelete.add(item);
                }
            } else {
                itemsToUpdate.add(item);
            }
        }

        for (Product_Sync_Queue__c item : itemsToUpdate) {
            processSingleItem(item, http);
        }

        if (!itemsToDelete.isEmpty()) {
            delete itemsToDelete;
        }

        return itemsToUpdate;
    }

    private void processSingleItem(Product_Sync_Queue__c item, Http http) {
        incrementAttemptCount(item);

        try {
            SyncOperationHandler handler = SyncOperationHandlerFactory.getHandler(item.Operation__c);
            HttpRequest req = handler.createRequest(item);
            
            logOutboundRequest(item, req);
            
            HttpResponse res = http.send(req);
            evaluateResponse(item, res);
        } catch (Exception e) {
            handleException(item, e);
        }
    }

    private void incrementAttemptCount(Product_Sync_Queue__c item) {
        item.Attempt_Count__c = (item.Attempt_Count__c == null ? 0 : item.Attempt_Count__c) + 1;
        item.Last_Attempt__c = System.now();
    }

    private void logOutboundRequest(Product_Sync_Queue__c item, HttpRequest req) {
        String requestLog = 'OUTBOUND ' + item.Operation__c + ' REQUEST | Endpoint: ' + req.getEndpoint();
        if (String.isNotBlank(req.getBody())) {
            requestLog += ' | Body: ' + req.getBody();
        }
        ErrorLogger.logInfo(requestLog, 'ProductSyncQueueable', 'processSingleItem');
    }

    private void evaluateResponse(Product_Sync_Queue__c item, HttpResponse res) {
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            handleSuccess(item, res);
        } else {
            handleFailure(item, res);
        }
    }

    private void handleSuccess(Product_Sync_Queue__c item, HttpResponse res) {
        item.Status__c = Util.PRODUCT_SYNC_QUEUE.STATUS.SUCCESS;
        item.Error_Message__c = '';
        ErrorLogger.logInfo(
            'OUTBOUND ' + item.Operation__c + ' SUCCESS | Status: ' + res.getStatusCode() + ' | Response: ' + res.getBody(),
            'ProductSyncQueueable',
            'handleSuccess'
        );
    }

    private void handleFailure(Product_Sync_Queue__c item, HttpResponse res) {
        item.Status__c = Util.PRODUCT_SYNC_QUEUE.STATUS.FAILED;
        item.Error_Message__c = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
        ErrorLogger.logWarning(
            'OUTBOUND ' + item.Operation__c + ' REJECTED | Status: ' + res.getStatusCode() + ' | Response: ' + res.getBody(),
            'ProductSyncQueueable',
            'handleFailure'
        );
    }

    private void handleException(Product_Sync_Queue__c item, Exception e) {
        item.Status__c = Util.PRODUCT_SYNC_QUEUE.STATUS.FAILED;
        item.Error_Message__c = e.getMessage();
        ErrorLogger.logException(e, 'ProductSyncQueueable', 'processSingleItem');
    }

    private void enqueueNextJobIfNeeded() {
        Integer pendingCount = [SELECT Count() FROM Product_Sync_Queue__c WHERE Status__c = 'Pending' LIMIT 1];
        
        if (pendingCount > 0 && !Test.isRunningTest()) {
            System.enqueueJob(new ProductSyncQueueable());
        }
    }
}