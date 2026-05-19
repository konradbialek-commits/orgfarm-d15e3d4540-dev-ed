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

        if (isExternal) {
            String correlationId = UUID.randomUUID().toString();

            String payload = JSON.serialize(
                new Map<String, String>{
                    'Product_Ids__c' => String.join(productIds, ','),
                    'Reason__c' => refundType +
                    ' - ' +
                    description,
                    'Case_Id__c' => correlationId,
                    'Order_id__c' => String.valueOf(orderId)
                }
            );

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Szymon_Org_API/services/data/v60.0/sobjects/External_Complaint__e');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                return 'EXTERNAL:' + correlationId;
            } else {
                throw new AuraHandledException('Callout failed: ' + res.getBody());
            }
        } else {
            Case localCase = new Case(
                Subject = 'Refund Request: ' + refundType,
                Description = description,
                Order__c = orderId,
                Refund_Status__c = 'Pending',
                Requested_Refund_Type__c = refundType,
                Has_External_Product__c = false
            );
            insert localCase;

            List<Case_Order_Product__c> caseOrderProducts = new List<Case_Order_Product__c>();
            for (OrderItem oi : items) {
                caseOrderProducts.add(
                    new Case_Order_Product__c(
                        Case__c = localCase.Id,
                        Order_Product__c = oi.Id,
                        Product_Name__c = oi.Product2.Name,
                        Is_External__c = false
                    )
                );
            }
            insert caseOrderProducts;

            update new Order(Id = orderId, ComplaintCaseId__c = localCase.Id);

            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setObjectId(localCase.Id);
            request.setSubmitterId(UserInfo.getUserId());
            Approval.process(request);

            return 'LOCAL:' + localCase.Id;
        }
    }
}
