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
        List<Product_Sync_Queue__c> itemsToUpdate = new List<Product_Sync_Queue__c>();
        List<Product_Sync_Queue__c> itemsToDelete = new List<Product_Sync_Queue__c>();

        refreshPayloadsAndFilter(queueItems, itemsToUpdate, itemsToDelete);

        Http http = new Http();
        for (Product_Sync_Queue__c item : itemsToUpdate) {
            processSingleItem(item, http);
        }

        if (!itemsToDelete.isEmpty()) {
            delete itemsToDelete;
        }

        return itemsToUpdate;
    }

    private void refreshPayloadsAndFilter(List<Product_Sync_Queue__c> queueItems, List<Product_Sync_Queue__c> itemsToUpdate, List<Product_Sync_Queue__c> itemsToDelete) {
        Set<Id> productIdsToRefresh = new Set<Id>();
        Map<Id, SyncOperationHandler> handlersByItemId = new Map<Id, SyncOperationHandler>();
        
        for (Product_Sync_Queue__c item : queueItems) {
            SyncOperationHandler handler = SyncOperationHandlerFactory.getHandler(item.Operation__c);
            handlersByItemId.put(item.Id, handler);
            
            Id requiredProdId = handler.getProductIdToRefresh(item);
            if (requiredProdId != null) {
                productIdsToRefresh.add(requiredProdId);
            }
        }

        Map<Id, Product2> freshProductsMap = productIdsToRefresh.isEmpty() ? new Map<Id, Product2>() : new Map<Id, Product2>([
            SELECT Id, Name, Description, ProductCode, Family, External_Product_Id__c 
            FROM Product2 
            WHERE Id IN :productIdsToRefresh
        ]);

        for (Product_Sync_Queue__c item : queueItems) {
            handlersByItemId.get(item.Id).prepareItem(item, freshProductsMap, itemsToUpdate, itemsToDelete);
        }
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