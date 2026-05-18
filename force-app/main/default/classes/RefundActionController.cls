public class RefundActionController {
    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderItems(Id orderId) {
        return [
            SELECT Id, Product2.Name, Product2.ProductCode, Product2.Is_External__c, Quantity, UnitPrice
            FROM OrderItem
            WHERE OrderId = :orderId
        ];
    }

    @AuraEnabled
    public static void processRefund(Id orderId, List<Id> orderItemIds, String refundType, String description, String correlationId) {
        List<OrderItem> items = [SELECT Id, Product2.Is_External__c FROM OrderItem WHERE Id IN :orderItemIds];

        Boolean isExternal = false;
        for (OrderItem oi : items) {
            if (oi.Product2.Is_External__c) {
                isExternal = true;
                break;
            }
        }

        if (isExternal) {
            Refund_Sync_Event__e ev = new Refund_Sync_Event__e(
                Action__c = 'REQUEST',
                Correlation_Id__c = correlationId,
                Order_Id__c = orderId,
                Refund_Type__c = refundType,
                Description__c = description,
                Target_Org__c = Util.PRODUCT_SYNC_QUEUE.TARGET_ORG.SZYMON_ORG
            );
            EventBus.publish(ev);
        } else {
            Case c = new Case(Subject = 'Refund Request: ' + refundType, Description = description);
            insert c;

            Refund_Sync_Event__e ev = new Refund_Sync_Event__e(
                Action__c = 'CONFIRMATION',
                Correlation_Id__c = correlationId,
                Case_Id__c = c.Id,
                Target_Org__c = 'LOCAL'
            );
            EventBus.publish(ev);
        }
    }
}
