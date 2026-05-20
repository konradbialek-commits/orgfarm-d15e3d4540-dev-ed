public with sharing class RefundApprovalController {
    @AuraEnabled
    public static void processApproval(Id caseId, String decision, String comments) {
        try {
            ProcessInstanceWorkitem workitem = [
                SELECT Id
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :caseId AND ActorId = :UserInfo.getUserId()
                LIMIT 1
            ];

            String action = (decision == 'Rejected') ? 'Reject' : 'Approve';

            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workitem.Id);
            req.setAction(action);
            req.setComments(comments);
            Approval.process(req);

            Case caseRecord = new Case(Id = caseId, Refund_Status__c = decision);
            update caseRecord;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
