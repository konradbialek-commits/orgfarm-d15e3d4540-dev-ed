public class ExternalComplaintHandler implements TriggerAction.AfterInsert {
    public void afterInsert(List<SObject> newList) {
        List<External_Complaint__e> events = (List<External_Complaint__e>) newList;

        Set<Id> orderIdsToVerify = new Set<Id>();

        for (External_Complaint__e ev : events) {
            if (String.isNotBlank(ev.Order_id__c)) {
                try {
                    orderIdsToVerify.add((Id) ev.Order_id__c);
                } catch (Exception e) {
                    ErrorLogger.logWarning(
                        'Invalid Order ID format received: ' + ev.Order_id__c,
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

        for (External_Complaint__e ev : events) {
            ErrorLogger.logInfo(
                'INBOUND EVENT RECEIVED | Type: External_Complaint__e | Payload: ' + JSON.serialize(ev),
                'ExternalComplaintHandler',
                'afterInsert'
            );

            Id validLocalOrderId = null;
            if (String.isNotBlank(ev.Order_id__c)) {
                try {
                    Id parsedOrderId = (Id) ev.Order_id__c;
                    if (localOrders.containsKey(parsedOrderId)) {
                        validLocalOrderId = parsedOrderId;
                    }
                } catch (Exception e) {
                }
            }

            String requestedType = '';
            if (String.isNotBlank(ev.Reason__c)) {
                if (ev.Reason__c.startsWith('Full')) {
                    requestedType = 'Full';
                } else if (ev.Reason__c.startsWith('Partial')) {
                    requestedType = 'Partial';
                }
            }

            Case newCase = new Case(
                Subject = 'External Refund Request',
                Description = 'Reason: ' + ev.Reason__c + '\nProducts: ' + ev.Product_Ids__c + '\nExternal Order ID: ' + ev.Order_id__c,
                Order__c = validLocalOrderId,
                Refund_Status__c = 'Pending',
                Requested_Refund_Type__c = requestedType,
                External_Case_Id__c = ev.Case_Id__c
            );

            inboundCasesToInsert.add(newCase);
            inboundIndexToEvent.put(inboundCasesToInsert.size() - 1, ev);
        }

        if (!inboundCasesToInsert.isEmpty()) {
            insert inboundCasesToInsert;

            List<External_Complaint_Response__e> responses = new List<External_Complaint_Response__e>();
            for (Integer i = 0; i < inboundCasesToInsert.size(); i++) {
                responses.add(
                    new External_Complaint_Response__e(
                        Case_Id__c = inboundIndexToEvent.get(i).Case_Id__c,
                        External_Case_Id__c = String.valueOf(inboundCasesToInsert[i].Id),
                        Status__c = 'Created'
                    )
                );
            }
            EventBus.publish(responses);
        }
    }
}
