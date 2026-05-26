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
        List<Case_Order_Product__c> caseProductsToUpdate = new List<Case_Order_Product__c>();

        for (LineItemUpdate item : updates) {
            Case_Order_Product__c caseProduct = new Case_Order_Product__c(Id = item.id, Refund_Status__c = item.status);

            if (item.status == Util.COMPLAINT.STATUS.APPROVED_PARTIAL && item.approvedAmount != null) {
                caseProduct.Refund_Amount__c = item.approvedAmount;
            }
            caseProductsToUpdate.add(caseProduct);
        }

        if (!caseProductsToUpdate.isEmpty()) {
            update caseProductsToUpdate;
        }

        List<ProcessInstanceWorkitem> workitems = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :caseId AND ActorId = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (!workitems.isEmpty()) {
            Approval.ProcessWorkitemRequest approvalRequest = new Approval.ProcessWorkitemRequest();
            approvalRequest.setWorkitemId(workitems[0].Id);
            approvalRequest.setAction(Util.COMPLAINT.ACTION.APPROVE);
            approvalRequest.setComments(comments);
            Approval.process(approvalRequest);
        }

        checkAndCompleteCaseApproval(caseId);
    }

    public static void rejectCase(Id caseId, String comments) {
        List<Case_Order_Product__c> caseProductsToUpdate = new List<Case_Order_Product__c>();
        for (Case_Order_Product__c caseProduct : [
            SELECT Id, Refund_Status__c
            FROM Case_Order_Product__c
            WHERE Case__c = :caseId AND Refund_Status__c = :Util.COMPLAINT.STATUS.PENDING AND Is_External__c = FALSE
        ]) {
            caseProduct.Refund_Status__c = Util.COMPLAINT.STATUS.REJECTED;
            caseProductsToUpdate.add(caseProduct);
        }

        if (!caseProductsToUpdate.isEmpty()) {
            update caseProductsToUpdate;
        }

        List<ProcessInstanceWorkitem> workitems = [
            SELECT Id
            FROM ProcessInstanceWorkitem
            WHERE ProcessInstance.TargetObjectId = :caseId AND ActorId = :UserInfo.getUserId()
            LIMIT 1
        ];

        if (!workitems.isEmpty()) {
            Approval.ProcessWorkitemRequest approvalRequest = new Approval.ProcessWorkitemRequest();
            approvalRequest.setWorkitemId(workitems[0].Id);
            approvalRequest.setAction(Util.COMPLAINT.ACTION.REJECT);
            approvalRequest.setComments(comments);
            Approval.process(approvalRequest);
        }

        checkAndCompleteCaseApproval(caseId);
    }

    public static void checkAndCompleteCaseApproval(Id caseId) {
        List<Case_Order_Product__c> allCaseProducts = [
            SELECT Refund_Status__c, Refund_Amount__c
            FROM Case_Order_Product__c
            WHERE Case__c = :caseId
        ];

        Boolean hasPending = false;
        Boolean hasRejected = false;
        Boolean hasPartial = false;
        Decimal totalApproved = 0;

        for (Case_Order_Product__c caseProductItem : allCaseProducts) {
            if (caseProductItem.Refund_Status__c == Util.COMPLAINT.STATUS.PENDING) {
                hasPending = true;
            } else if (
                caseProductItem.Refund_Status__c == Util.COMPLAINT.STATUS.REJECTED ||
                caseProductItem.Refund_Status__c == Util.COMPLAINT.RESPONSE_STATUS.FAILED
            ) {
                hasRejected = true;
            } else if (caseProductItem.Refund_Status__c == Util.COMPLAINT.STATUS.APPROVED_PARTIAL) {
                hasPartial = true;
                totalApproved += (caseProductItem.Refund_Amount__c != null ? caseProductItem.Refund_Amount__c : 0);
            } else if (caseProductItem.Refund_Status__c == Util.COMPLAINT.STATUS.APPROVED_FULL) {
                totalApproved += (caseProductItem.Refund_Amount__c != null ? caseProductItem.Refund_Amount__c : 0);
            }
        }

        if (hasPending) {
            return;
        }

        String finalRefundStatus;
        if (hasRejected) {
            finalRefundStatus = Util.COMPLAINT.STATUS.REJECTED;
            totalApproved = 0;
        } else {
            finalRefundStatus = hasPartial ? Util.COMPLAINT.STATUS.APPROVED_PARTIAL : Util.COMPLAINT.STATUS.APPROVED_FULL;
        }

        Case relatedCase = [SELECT Order__c FROM Case WHERE Id = :caseId LIMIT 1];
        Case caseUpdate = new Case(
            Id = caseId,
            Status = Util.COMPLAINT.CASE_STATUS.CLOSED,
            Refund_Status__c = finalRefundStatus,
            Refund_Amount__c = totalApproved
        );

        update caseUpdate;

        if (relatedCase.Order__c != null) {
            update new Order(Id = relatedCase.Order__c, Refund_Status__c = finalRefundStatus, Refunded_Amount__c = totalApproved);
        }

        List<Case> caseDetails = [SELECT CaseNumber, OwnerId FROM Case WHERE Id = :caseId LIMIT 1];
        if (!caseDetails.isEmpty()) {
            caseDetails[0].Refund_Status__c = finalRefundStatus;
            NotificationUtil.sendStatusNotifications(new List<Case>{ caseDetails[0] });
        }
    }
}
