public class ExternalComplaintResponseHandler implements TriggerAction.AfterInsert {
    public void afterInsert(List<SObject> newList) {
        List<External_Complaint_Response__e> responses = (List<External_Complaint_Response__e>) newList;
        Map<String, External_Complaint_Response__e> responseMap = new Map<String, External_Complaint_Response__e>();

        for (External_Complaint_Response__e response : responses) {
            ErrorLogger.logInfo(
                'INBOUND RESPONSE RECEIVED | Type: External_Complaint_Response__e | Payload: ' + JSON.serialize(response),
                'ExternalComplaintResponseHandler',
                'afterInsert'
            );
            if (String.isNotBlank(response.Case_Id__c) && String.isNotBlank(response.Status__c)) {
                responseMap.put(response.Case_Id__c, response);
            }
        }

        if (!responseMap.isEmpty()) {
            List<Case> casesToUpdate = [
                SELECT Id, CaseNumber, OwnerId, External_Case_Id__c, Refund_Status__c, Refund_Amount__c, Requested_Refund_Type__c
                FROM Case
                WHERE External_Case_Id__c IN :responseMap.keySet()
            ];

            for (Case c : casesToUpdate) {
                External_Complaint_Response__e eventRec = responseMap.get(c.External_Case_Id__c);
                c.Refund_Status__c = eventRec.Status__c;

                if (eventRec.Final_Refund_Amount__c != null) {
                    c.Refund_Amount__c = eventRec.Final_Refund_Amount__c;
                }

                if (String.isNotBlank(eventRec.Final_Refund_Type__c)) {
                    c.Requested_Refund_Type__c = eventRec.Final_Refund_Type__c;
                }
            }

            if (!casesToUpdate.isEmpty()) {
                update casesToUpdate;
                NotificationUtil.sendStatusNotifications(casesToUpdate);
            }
        }
    }
}
