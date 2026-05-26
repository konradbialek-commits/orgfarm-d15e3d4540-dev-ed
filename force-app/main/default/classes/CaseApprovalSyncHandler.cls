public class CaseApprovalSyncHandler implements TriggerAction.AfterUpdate {
    public class RefundLineResponse {
        public String productId;
        public String status;
        public Decimal refundAmount;
        public String refundType;
    }

    public void afterUpdate(List<SObject> newRecordsList, List<SObject> oldRecordsList) {
        List<Case> newCaseRecords = (List<Case>) newRecordsList;
        List<Case> oldCaseRecords = (List<Case>) oldRecordsList;

        List<String> outboundResponses = new List<String>();
        Set<Id> externalCaseIds = new Set<Id>();

        for (Integer index = 0; index < newCaseRecords.size(); index++) {
            if (
                newCaseRecords[index].Refund_Status__c != oldCaseRecords[index].Refund_Status__c &&
                newCaseRecords[index].Order__c == null &&
                String.isNotBlank(newCaseRecords[index].External_Case_Id__c)
            ) {
                externalCaseIds.add(newCaseRecords[index].Id);
            }
        }

        if (!externalCaseIds.isEmpty()) {
            Map<Id, Case> casesWithLineItems = new Map<Id, Case>(
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

            for (Case evaluatedCase : casesWithLineItems.values()) {
                if (
                    evaluatedCase.Refund_Status__c == Util.COMPLAINT.STATUS.APPROVED_FULL ||
                    evaluatedCase.Refund_Status__c == Util.COMPLAINT.STATUS.APPROVED_PARTIAL ||
                    evaluatedCase.Refund_Status__c == Util.COMPLAINT.STATUS.REJECTED
                ) {
                    List<RefundLineResponse> refundResponses = new List<RefundLineResponse>();
                    for (Case_Order_Product__c caseProductItem : evaluatedCase.Case_Order_Products__r) {
                        RefundLineResponse itemResponse = new RefundLineResponse();
                        itemResponse.productId = caseProductItem.External_Product_Id__c;
                        itemResponse.status = caseProductItem.Refund_Status__c;
                        itemResponse.refundAmount = caseProductItem.Refund_Amount__c;
                        itemResponse.refundType = caseProductItem.Requested_Refund_Type__c;
                        refundResponses.add(itemResponse);
                    }

                    External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(
                        Case_Id__c = evaluatedCase.External_Case_Id__c,
                        Status__c = evaluatedCase.Refund_Status__c,
                        Line_Items_JSON__c = JSON.serialize(refundResponses)
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
