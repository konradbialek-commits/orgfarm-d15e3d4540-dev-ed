public class RefundEventForwarderQueueable implements Queueable, Database.AllowsCallouts {
    private static final String TARGET_NAMED_CREDENTIAL = 'Szymon_Org_API';

    private List<SObject> eventsToForward;
    private String targetSObjectName;

    public RefundEventForwarderQueueable(List<SObject> events, String targetSObjectName) {
        this.eventsToForward = events;
        this.targetSObjectName = targetSObjectName;
    }

    public void execute(QueueableContext context) {
        Http http = new Http();
        String targetEndpoint = 'callout:' + TARGET_NAMED_CREDENTIAL + '/services/data/v60.0/sobjects/' + targetSObjectName;

        for (SObject ev : eventsToForward) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(targetEndpoint);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');

            Map<String, Object> payload = new Map<String, Object>();

            if (targetSObjectName == 'External_Complaint__e') {
                External_Complaint__e ec = (External_Complaint__e) ev;
                payload.put('Order_id__c', ec.Order_id__c);
                payload.put('Case_Id__c', ec.Case_Id__c);
                payload.put('Reason__c', ec.Reason__c);
                payload.put('Product_Ids__c', ec.Product_Ids__c);
            } else if (targetSObjectName == 'External_Complaint_Response__e') {
                External_Complaint_Response__e ecr = (External_Complaint_Response__e) ev;
                payload.put('Case_Id__c', ecr.Case_Id__c);
                payload.put('External_Case_Id__c', ecr.External_Case_Id__c);
                payload.put('Status__c', ecr.Status__c);
            }

            String requestBody = JSON.serialize(payload);
            req.setBody(requestBody);

            try {
                ErrorLogger.logInfo(
                    'OUTBOUND REQUEST | Endpoint: ' + targetEndpoint + ' | Payload: ' + requestBody,
                    'RefundEventForwarderQueueable',
                    'execute'
                );

                HttpResponse res = http.send(req);

                if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    ErrorLogger.logInfo(
                        'OUTBOUND SUCCESS | Status: ' + res.getStatusCode() + ' | Response: ' + res.getBody(),
                        'RefundEventForwarderQueueable',
                        'execute'
                    );
                } else {
                    ErrorLogger.logWarning(
                        'OUTBOUND REJECTED | Status: ' + res.getStatusCode() + ' | Response: ' + res.getBody(),
                        'RefundEventForwarderQueueable',
                        'execute'
                    );
                }
            } catch (Exception e) {
                ErrorLogger.logException(e, 'RefundEventForwarderQueueable', 'execute');
            }
        }
    }
}
