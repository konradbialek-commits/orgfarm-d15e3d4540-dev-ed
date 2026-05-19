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
        List<OrderItem> items = [
            SELECT Id, Product2.Name, Product2.ProductCode, Product2.Is_External__c
            FROM OrderItem
            WHERE Id IN :orderItemIds
        ];

        Boolean isExternal = false;
        List<String> productIds = new List<String>();

        for (OrderItem oi : items) {
            productIds.add(oi.Product2Id);
            if (oi.Product2.Is_External__c) {
                isExternal = true;
            }
        }

        Case localCase = new Case(
            Subject = 'Refund Request: ' + refundType,
            Description = description,
            Order__c = orderId,
            Refund_Status__c = 'Pending',
            Requested_Refund_Type__c = refundType,
            Has_External_Product__c = isExternal
        );
        insert localCase;

        List<Case_Order_Product__c> caseOrderProducts = new List<Case_Order_Product__c>();
        for (OrderItem oi : items) {
            caseOrderProducts.add(
                new Case_Order_Product__c(
                    Case__c = localCase.Id,
                    Order_Product__c = oi.Id,
                    Product_Name__c = oi.Product2.Name,
                    Is_External__c = oi.Product2.Is_External__c
                )
            );
        }
        insert caseOrderProducts;

        update new Order(Id = orderId, ComplaintCaseId__c = localCase.Id);

        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setObjectId(localCase.Id);
        request.setSubmitterId(UserInfo.getUserId());
        Approval.process(request);

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
