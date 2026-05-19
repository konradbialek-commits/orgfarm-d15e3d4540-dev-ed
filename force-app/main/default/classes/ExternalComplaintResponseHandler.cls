public class ExternalComplaintResponseHandler implements TriggerAction.AfterInsert {
    public void afterInsert(List<SObject> newList) {
        List<External_Complaint_Response__e> responses = (List<External_Complaint_Response__e>) newList;

        for (External_Complaint_Response__e response : responses) {
            ErrorLogger.logInfo(
                'INBOUND RESPONSE RECEIVED | Type: External_Complaint_Response__e | Payload: ' + JSON.serialize(response),
                'ExternalComplaintResponseHandler',
                'afterInsert'
            );
        }
    }
}
