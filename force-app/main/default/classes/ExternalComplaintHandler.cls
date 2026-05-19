public class ExternalComplaintHandler implements TriggerAction.AfterInsert {
    public void afterInsert(List<SObject> newList) {
        List<External_Complaint__e> events = (List<External_Complaint__e>) newList;
        Set<Id> caseIdsToVerify = new Set<Id>();

        for (External_Complaint__e ev : events) {
            try {
                caseIdsToVerify.add((Id) ev.Case_Id__c);
            } catch (Exception e) {
            }
        }

        Map<Id, Case> localCases = new Map<Id, Case>([SELECT Id FROM Case WHERE Id IN :caseIdsToVerify]);

        List<External_Complaint__e> outboundEvents = new List<External_Complaint__e>();
        List<Case> inboundCasesToInsert = new List<Case>();
        Map<Integer, External_Complaint__e> inboundIndexToEvent = new Map<Integer, External_Complaint__e>();

        for (External_Complaint__e ev : events) {
            Id parsedId;
            try {
                parsedId = (Id) ev.Case_Id__c;
            } catch (Exception e) {
            }

            if (parsedId != null && localCases.containsKey(parsedId)) {
                outboundEvents.add(ev);
            } else {
                ErrorLogger.logInfo(
                    'INBOUND EVENT RECEIVED | Type: External_Complaint__e | Payload: ' + JSON.serialize(ev),
                    'ExternalComplaintHandler',
                    'afterInsert'
                );

                Id parsedOrderId;
                try {
                    parsedOrderId = (Id) ev.Order_id__c;
                } catch (Exception e) {
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
                    Description = 'Reason: ' + ev.Reason__c + '\nProducts: ' + ev.Product_Ids__c,
                    Order__c = parsedOrderId,
                    Refund_Status__c = 'Pending',
                    Requested_Refund_Type__c = requestedType,
                    External_Case_Id__c = ev.Case_Id__c
                );
                inboundCasesToInsert.add(newCase);
                inboundIndexToEvent.put(inboundCasesToInsert.size() - 1, ev);
            }
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

        if (!outboundEvents.isEmpty()) {
            System.enqueueJob(new RefundEventForwarderQueueable(outboundEvents, 'External_Complaint__e'));
        }
    }
}
