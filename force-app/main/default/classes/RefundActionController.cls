public class RefundActionController {
    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderItems(Id orderId) {
        return [
            SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, Product2.Is_External__c, Quantity, UnitPrice
            FROM OrderItem
            WHERE OrderId = :orderId
        ];
    }

    @AuraEnabled
    public static String processRefund(Id orderId, List<Id> orderItemIds, String refundType, String description) {
        List<OrderItem> items = [
            SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, Product2.Is_External__c
            FROM OrderItem
            WHERE Id IN :orderItemIds
        ];

        List<OrderItem> localItems = new List<OrderItem>();
        List<String> externalProductIds = new List<String>();

        for (OrderItem oi : items) {
            if (oi.Product2.Is_External__c) {
                externalProductIds.add(oi.Product2Id);
            } else {
                localItems.add(oi);
            }
        }

        Map<String, String> responseMap = new Map<String, String>();

        if (!externalProductIds.isEmpty()) {
            String correlationId = UUID.randomUUID().toString();

            String payload = JSON.serialize(
                new Map<String, String>{
                    'Product_Ids__c' => String.join(externalProductIds, ','),
                    'Reason__c' => refundType +
                    ' - ' +
                    description,
                    'Case_Id__c' => correlationId,
                    'Order_id__c' => String.valueOf(orderId)
                }
            );

            HttpRequest req = new HttpRequest();
            req.setEndpoint(Util.COMPLAINT.ENDPOINT_EXTERNAL_COMPLAINT);
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(payload);

            ErrorLogger.logInfo('OUTBOUND External_Complaint__e REQUEST | Payload: ' + payload, 'RefundActionController', 'processRefund');

            try {
                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    ErrorLogger.logInfo(
                        'OUTBOUND External_Complaint__e SUCCESS | Status: ' + res.getStatusCode() + ' | Response: ' + res.getBody(),
                        'RefundActionController',
                        'processRefund'
                    );
                    responseMap.put('correlationId', correlationId);
                } else {
                    ErrorLogger.logWarning(
                        'OUTBOUND External_Complaint__e FAILED | Status: ' + res.getStatusCode() + ' | Response: ' + res.getBody(),
                        'RefundActionController',
                        'processRefund'
                    );
                    throw new AuraHandledException('Callout failed: ' + res.getBody());
                }
            } catch (Exception e) {
                ErrorLogger.logException(e, 'RefundActionController', 'processRefund');
                throw new AuraHandledException('Callout failed: ' + e.getMessage());
            }
        }

        if (!localItems.isEmpty()) {
            Case localCase = new Case(
                Subject = Util.COMPLAINT.SUBJECT.LOCAL_REFUND + refundType,
                Description = description,
                Order__c = orderId,
                Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                Requested_Refund_Type__c = refundType,
                Has_External_Product__c = false
            );
            insert localCase;

            List<Case_Order_Product__c> caseOrderProducts = new List<Case_Order_Product__c>();
            for (OrderItem oi : localItems) {
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

            responseMap.put('localCaseId', localCase.Id);
        }

        return JSON.serialize(responseMap);
    }
}
