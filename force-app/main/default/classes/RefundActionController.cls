public class RefundActionController {
    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderItems(Id orderId) {
        try {
            return RefundActionService.getOrderItems(orderId);
        } catch (Exception e) {
            AuraHandledException auraEx = new AuraHandledException(e.getMessage());
            auraEx.setMessage(e.getMessage());
            throw auraEx;
        }
    }

    @AuraEnabled
    public static RefundActionService.RefundResponse processRefund(Id orderId, String description, String refundItemsJSON) {
        try {
            return RefundActionService.processRefund(orderId, description, refundItemsJSON);
        } catch (Exception e) {
            AuraHandledException auraEx = new AuraHandledException(e.getMessage());
            auraEx.setMessage(e.getMessage());
            throw auraEx;
        }
    }

    @AuraEnabled
    public static Id getCaseIdByCorrelationId(String correlationId) {
        List<Case> matchingCases = [
            SELECT Id
            FROM Case
            WHERE External_Case_Id__c = :correlationId
            LIMIT 1
        ];
        return matchingCases.isEmpty() ? null : matchingCases[0].Id;
    }
}
