public class RefundActionController {
    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderItems(Id orderId) {
        try {
            return RefundActionService.getOrderItems(orderId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static RefundActionService.RefundResponse processRefund(Id orderId, String description, String refundItemsJSON) {
        try {
            return RefundActionService.processRefund(orderId, description, refundItemsJSON);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}
