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
    public static String processRefund(Id orderId, List<Id> orderItemIds, String refundType, String description) {
        List<OrderItem> items = [SELECT Id, Product2.Is_External__c FROM OrderItem WHERE Id IN :orderItemIds];

        Boolean isExternal = false;
        List<String> productIds = new List<String>();

        for (OrderItem oi : items) {
            productIds.add(oi.Id);
            if (oi.Product2.Is_External__c) {
                isExternal = true;
            }
        }

        Case localCase = new Case(Subject = 'Refund Request: ' + refundType, Description = description);
        insert localCase;

        if (isExternal) {
            External_Complaint__e ev = new External_Complaint__e(
                Order_id__c = String.valueOf(orderId),
                Case_Id__c = String.valueOf(localCase.Id),
                Reason__c = refundType + ' - ' + description,
                Product_Ids__c = String.join(productIds, ',')
            );
            EventBus.publish(ev);
        } else {
            External_Complaint_Response__e ev = new External_Complaint_Response__e(
                Case_Id__c = String.valueOf(localCase.Id),
                External_Case_Id__c = String.valueOf(localCase.Id),
                Status__c = 'Created Locally'
            );
            EventBus.publish(ev);
        }

        return localCase.Id;
    }
}
