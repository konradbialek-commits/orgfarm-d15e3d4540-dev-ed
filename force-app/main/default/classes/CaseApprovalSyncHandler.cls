public class CaseApprovalSyncHandler implements TriggerAction.AfterUpdate {
    public class ResponseLineDTO {
        public String productId;
        public String status;
        public Decimal refundAmount;
        public String refundType;
    }

    public void afterUpdate(List<SObject> newList, List<SObject> oldList) {
        List<Case> newCases = (List<Case>) newList;
        List<Case> oldCases = (List<Case>) oldList;

        List<String> outboundResponses = new List<String>();
        Set<Id> externalCaseIds = new Set<Id>();

        for (Integer i = 0; i < newCases.size(); i++) {
            if (
                newCases[i].Refund_Status__c != oldCases[i].Refund_Status__c &&
                newCases[i].Order__c == null &&
                String.isNotBlank(newCases[i].External_Case_Id__c)
            ) {
                externalCaseIds.add(newCases[i].Id);
            }
        }

        if (!externalCaseIds.isEmpty()) {
            Map<Id, Case> caseWithLines = new Map<Id, Case>(
                [
                    SELECT
                        Id,
                        External_Case_Id__c,
                        Refund_Status__c,
                        (
                            SELECT External_Product_Id__c, Refund_Status__c, Refund_Amount__c, Requested_Refund_Type__c
                            FROM Case_Order_Products__r
                            WHERE External_Product_Id__c != NULL
                        )
                    FROM Case
                    WHERE Id IN :externalCaseIds
                ]
            );

            for (Case c : caseWithLines.values()) {
                if (
                    c.Refund_Status__c == 'Approved Full Refund' ||
                    c.Refund_Status__c == 'Approved Partial Refund' ||
                    c.Refund_Status__c == 'Rejected'
                ) {
                    List<ResponseLineDTO> dtos = new List<ResponseLineDTO>();
                    for (Case_Order_Product__c line : c.Case_Order_Products__r) {
                        ResponseLineDTO dto = new ResponseLineDTO();
                        dto.productId = line.External_Product_Id__c;
                        dto.status = line.Refund_Status__c;
                        dto.refundAmount = line.Refund_Amount__c;
                        dto.refundType = line.Requested_Refund_Type__c;
                        dtos.add(dto);
                    }

                    External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(
                        Case_Id__c = c.External_Case_Id__c,
                        Status__c = c.Refund_Status__c,
                        Line_Items_JSON__c = JSON.serialize(dtos)
                    );
                    outboundResponses.add(JSON.serialize(responseEvent));
                }
            }
        }

        if (!outboundResponses.isEmpty() && !System.isBatch() && !System.isQueueable()) {
            System.enqueueJob(new ComplaintResponseQueueable(outboundResponses));
        }
    }
}
