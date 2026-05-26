public with sharing class RefundApprovalController {
    @AuraEnabled
    public static void processApproval(Id caseProductId, String decision, String comments, Decimal approvedAmount) {
        try {
            ProcessInstanceWorkitem workitem = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :caseProductId AND ActorId = :UserInfo.getUserId()
                LIMIT 1
            ];

            String action = (decision == 'Rejected') ? 'Reject' : 'Approve';

            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workitem.Id);
            req.setAction(action);
            req.setComments(comments);
            Approval.process(req);

            Case_Order_Product__c copRecord = new Case_Order_Product__c(Id = caseProductId, Refund_Status__c = decision);

            if (approvedAmount != null && decision == 'Approved Partial Refund') {
                copRecord.Refund_Amount__c = approvedAmount;
            }

            update copRecord;
        } catch (Exception e) {
            AuraHandledException auraEx = new AuraHandledException(e.getMessage());
            auraEx.setMessage(e.getMessage());
            throw auraEx;
        }
    }
}
