public class RefundApprovalService {
    public class ApprovalException extends Exception {
    }

    public class LineItemUpdate {
        public Id id;
        public String status;
        public Decimal approvedAmount;
    }

    public static List<Case_Order_Product__c> getCaseProducts(Id caseId) {
        return [
            SELECT Id, Product_Name__c, Requested_Refund_Type__c, Refund_Amount__c, Refund_Status__c, Is_External__c
            FROM Case_Order_Product__c
            WHERE Case__c = :caseId
        ];
    }

    public static void processBulkApproval(Id caseId, String comments, String lineItemsJSON) {
        List<LineItemUpdate> updates = (List<LineItemUpdate>) JSON.deserialize(lineItemsJSON, List<LineItemUpdate>.class);
        List<Case_Order_Product__c> copsToUpdate = new List<Case_Order_Product__c>();

        for (LineItemUpdate item : updates) {
            Case_Order_Product__c cop = new Case_Order_Product__c(Id = item.id, Refund_Status__c = item.status);

            if (item.status == Util.COMPLAINT.STATUS.APPROVED_PARTIAL && item.approvedAmount != null) {
                cop.Refund_Amount__c = item.approvedAmount;
            }
            copsToUpdate.add(cop);
        }

        if (!copsToUpdate.isEmpty()) {
            update copsToUpdate;
        }

        List<ProcessInstanceWorkitem> workitems = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :caseId AND ActorId = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (!workitems.isEmpty()) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workitems[0].Id);
            req.setAction(Util.COMPLAINT.ACTION.APPROVE);
            req.setComments(comments);
            Approval.process(req);
        }
    }

    public static void rejectCase(Id caseId, String comments) {
        List<Case_Order_Product__c> copsToUpdate = new List<Case_Order_Product__c>();
        for (Case_Order_Product__c cop : [
            SELECT Id, Refund_Status__c
            FROM Case_Order_Product__c
            WHERE Case__c = :caseId AND Refund_Status__c = :Util.COMPLAINT.STATUS.PENDING
        ]) {
            cop.Refund_Status__c = Util.COMPLAINT.STATUS.REJECTED;
            copsToUpdate.add(cop);
        }

        if (!copsToUpdate.isEmpty()) {
            update copsToUpdate;
        }

        List<ProcessInstanceWorkitem> workitems = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :caseId AND ActorId = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (!workitems.isEmpty()) {
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workitems[0].Id);
            req.setAction(Util.COMPLAINT.ACTION.REJECT);
            req.setComments(comments);
            Approval.process(req);
        }
    }
}
