public with sharing class RefundApprovalController {
    @AuraEnabled(cacheable=true)
    public static List<Case_Order_Product__c> getCaseProducts(Id caseId) {
        try {
            return RefundApprovalService.getCaseProducts(caseId);
        } catch (Exception e) {
            AuraHandledException auraEx = new AuraHandledException(e.getMessage());
            auraEx.setMessage(e.getMessage());
            throw auraEx;
        }
    }

    @AuraEnabled
    public static void processBulkApproval(Id caseId, String comments, String lineItemsJSON) {
        try {
            RefundApprovalService.processBulkApproval(caseId, comments, lineItemsJSON);
        } catch (Exception e) {
            AuraHandledException auraEx = new AuraHandledException(e.getMessage());
            auraEx.setMessage(e.getMessage());
            throw auraEx;
        }
    }

    @AuraEnabled
    public static void rejectCase(Id caseId, String comments) {
        try {
            RefundApprovalService.rejectCase(caseId, comments);
        } catch (Exception e) {
            AuraHandledException auraEx = new AuraHandledException(e.getMessage());
            auraEx.setMessage(e.getMessage());
            throw auraEx;
        }
    }
}
