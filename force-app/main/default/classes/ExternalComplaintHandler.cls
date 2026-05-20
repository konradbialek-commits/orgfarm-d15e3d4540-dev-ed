public class ExternalComplaintHandler implements TriggerAction.AfterInsert {
    public void afterInsert(List<SObject> newList) {
        List<External_Complaint__e> events = (List<External_Complaint__e>) newList;

        Set<Id> orderIdsToVerify = new Set<Id>();

        for (External_Complaint__e complaintEvent : events) {
            if (String.isNotBlank(complaintEvent.Order_id__c)) {
                try {
                    orderIdsToVerify.add((Id) complaintEvent.Order_id__c);
                } catch (Exception e) {
                    ErrorLogger.logWarning(
                        'Invalid Order ID format received: ' + complaintEvent.Order_id__c,
                        'ExternalComplaintHandler',
                        'afterInsert'
                    );
                }
            }
        }

        Map<Id, Order> localOrders = new Map<Id, Order>();
        if (!orderIdsToVerify.isEmpty()) {
            localOrders = new Map<Id, Order>([SELECT Id FROM Order WHERE Id IN :orderIdsToVerify]);
        }

        List<Case> inboundCasesToInsert = new List<Case>();
        Map<Integer, External_Complaint__e> inboundIndexToEvent = new Map<Integer, External_Complaint__e>();

        for (External_Complaint__e complaintEvent : events) {
            ErrorLogger.logInfo(
                'INBOUND EVENT RECEIVED | Type: External_Complaint__e | Payload: ' + JSON.serialize(complaintEvent),
                'ExternalComplaintHandler',
                'afterInsert'
            );

            Id validLocalOrderId = null;
            if (String.isNotBlank(complaintEvent.Order_id__c)) {
                try {
                    Id parsedOrderId = (Id) complaintEvent.Order_id__c;
                    if (localOrders.containsKey(parsedOrderId)) {
                        validLocalOrderId = parsedOrderId;
                    }
                } catch (Exception e) {
                }
            }

            String requestedType = '';
            if (String.isNotBlank(complaintEvent.Reason__c)) {
                if (complaintEvent.Reason__c.startsWith(Util.COMPLAINT.TYPE.FULL)) {
                    requestedType = Util.COMPLAINT.TYPE.FULL;
                } else if (complaintEvent.Reason__c.startsWith(Util.COMPLAINT.TYPE.PARTIAL)) {
                    requestedType = Util.COMPLAINT.TYPE.PARTIAL;
                }
            }

            Case newCase = new Case(
                Subject = Util.COMPLAINT.SUBJECT.EXTERNAL_REFUND,
                Description = 'Reason: ' +
                    complaintEvent.Reason__c +
                    '\nProducts: ' +
                    complaintEvent.Product_Ids__c +
                    '\nExternal Order ID: ' +
                    complaintEvent.Order_id__c,
                Order__c = validLocalOrderId,
                Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                Requested_Refund_Type__c = requestedType,
                External_Case_Id__c = complaintEvent.Case_Id__c
            );

            inboundCasesToInsert.add(newCase);
            inboundIndexToEvent.put(inboundCasesToInsert.size() - 1, complaintEvent);
        }

        if (!inboundCasesToInsert.isEmpty()) {
            insert inboundCasesToInsert;

            List<String> responsePayloads = new List<String>();
            for (Integer i = 0; i < inboundCasesToInsert.size(); i++) {
                Map<String, String> responseBody = new Map<String, String>{
                    'Case_Id__c' => inboundIndexToEvent.get(i).Case_Id__c,
                    'External_Case_Id__c' => String.valueOf(inboundCasesToInsert[i].Id),
                    'Status__c' => Util.COMPLAINT.RESPONSE_STATUS.CREATED
                };
                responsePayloads.add(JSON.serialize(responseBody));
            }

            if (!System.isFuture() && !System.isBatch()) {
                sendResponses(responsePayloads);
            }
        }
    }

    @future(callout=true)
    public static void sendResponses(List<String> payloads) {
        Http http = new Http();
        for (String payload : payloads) {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Util.COMPLAINT.ENDPOINT_COMPLAINT_RESPONSE);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(payload);

            try {
                HttpResponse response = http.send(request);
                if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                    ErrorLogger.logInfo('OUTBOUND RESPONSE SUCCESS | ' + response.getBody(), 'ExternalComplaintHandler', 'sendResponses');
                } else {
                    ErrorLogger.logWarning('OUTBOUND RESPONSE FAILED | ' + response.getBody(), 'ExternalComplaintHandler', 'sendResponses');
                }
            } catch (Exception e) {
                ErrorLogger.logException(e, 'ExternalComplaintHandler', 'sendResponses');
            }
        }
    }
}
