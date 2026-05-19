public class ExternalComplaintResponseHandler implements TriggerAction.AfterInsert {
    public void afterInsert(List<SObject> newList) {
        List<External_Complaint_Response__e> events = (List<External_Complaint_Response__e>) newList;
        Set<Id> caseIdsToVerify = new Set<Id>();

        for (External_Complaint_Response__e ev : events) {
            try {
                caseIdsToVerify.add((Id) ev.Case_Id__c);
            } catch (Exception e) {
            }
        }

        Map<Id, Case> localCases = new Map<Id, Case>([SELECT Id FROM Case WHERE Id IN :caseIdsToVerify]);

        List<External_Complaint_Response__e> outboundEvents = new List<External_Complaint_Response__e>();
        List<Case> casesToUpdate = new List<Case>();

        for (External_Complaint_Response__e ev : events) {
            Id parsedId;
            try {
                parsedId = (Id) ev.Case_Id__c;
            } catch (Exception e) {
            }

            if (parsedId != null && localCases.containsKey(parsedId)) {
                ErrorLogger.logInfo(
                    'INBOUND EVENT RECEIVED | Type: External_Complaint_Response__e | Payload: ' + JSON.serialize(ev),
                    'ExternalComplaintResponseHandler',
                    'afterInsert'
                );

                Case c = new Case(Id = parsedId, External_Case_Id__c = ev.External_Case_Id__c);
                casesToUpdate.add(c);
            } else {
                outboundEvents.add(ev);
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }

        if (!outboundEvents.isEmpty()) {
            System.enqueueJob(new RefundEventForwarderQueueable(outboundEvents, 'External_Complaint_Response__e'));
        }
    }
}
