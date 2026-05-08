public class ProductSyncQueueable implements Queueable, Database.AllowsCallouts {

    public void execute(QueueableContext context) {
        List<Product_Sync_Queue__c> queueItems = [
            SELECT Id, Operation__c, Payload__c, Attempt_Count__c, Product__c, Product__r.External_Product_Id__c
            FROM Product_Sync_Queue__c
            WHERE Status__c IN ('Pending', 'Failed')
            AND Attempt_Count__c < 3
            LIMIT 50
        ];

        if (queueItems.isEmpty()) {
            return;
        }

        Http http = new Http();

        for (Product_Sync_Queue__c item : queueItems) {
            item.Attempt_Count__c = (item.Attempt_Count__c == null ? 0 : item.Attempt_Count__c) + 1;
            item.Last_Attempt__c = System.now();

            HttpRequest req = new HttpRequest();

            if (item.Operation__c == 'DELETE') {
                Map<String, Object> payloadMap = (Map<String, Object>) JSON.deserializeUntyped(item.Payload__c);
                String extId = (String) payloadMap.get('externalProductId');
                
                req.setEndpoint('callout:Szymon_Org_API/services/apexrest/v1/products/' + extId);
                req.setMethod('DELETE');
            } else {
                req.setEndpoint('callout:Szymon_Org_API/services/apexrest/v1/products');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');
                req.setBody(item.Payload__c);
            }

            try {
                String requestLog = 'OUTBOUND ' + item.Operation__c + ' REQUEST | Endpoint: ' + req.getEndpoint();
                if (item.Operation__c != 'DELETE') {
                    requestLog += ' | Body: ' + item.Payload__c;
                }
                ErrorLogger.logInfo(requestLog, 'ProductSyncQueueable', 'execute');

                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    item.Status__c = 'Success';
                    item.Error_Message__c = '';
                    
                    ErrorLogger.logInfo(
                        'OUTBOUND ' + item.Operation__c + ' SUCCESS | Status: ' + res.getStatusCode() + ' | Response: ' + res.getBody(),
                        'ProductSyncQueueable',
                        'execute'
                    );
                } else {
                    item.Status__c = 'Failed';
                    item.Error_Message__c = 'HTTP ' + res.getStatusCode() + ': ' + res.getBody();
                    
                    ErrorLogger.logWarning(
                        'OUTBOUND ' + item.Operation__c + ' REJECTED | Status: ' + res.getStatusCode() + ' | Response: ' + res.getBody(),
                        'ProductSyncQueueable',
                        'execute'
                    );
                }
            } catch (Exception e) {
                item.Status__c = 'Failed';
                item.Error_Message__c = e.getMessage();
                
                ErrorLogger.logException(e, 'ProductSyncQueueable', 'execute');
            }
        }

        update queueItems;

        Integer pendingCount = [SELECT Count() FROM Product_Sync_Queue__c WHERE Status__c = 'Pending' LIMIT 1];
        
        if (pendingCount > 0 && !Test.isRunningTest()) {
            System.enqueueJob(new ProductSyncQueueable());
        }
    }
}