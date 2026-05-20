public class RefundActionController {
    @AuraEnabled(cacheable=true)
    public static List<OrderItem> getOrderItems(Id orderId) {
        return [
            SELECT
                Id,
                Product2Id,
                Product2.Name,
                Product2.ProductCode,
                Product2.Is_External__c,
                Product2.External_Product_Id__c,
                Quantity,
                UnitPrice
            FROM OrderItem
            WHERE OrderId = :orderId
        ];
    }

    @AuraEnabled
    public static String processRefund(Id orderId, List<Id> orderItemIds, String refundType, String description) {
        List<OrderItem> selectedOrderItems = [
            SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, Product2.Is_External__c, Product2.External_Product_Id__c
            FROM OrderItem
            WHERE Id IN :orderItemIds
        ];

        List<OrderItem> localOrderItems = new List<OrderItem>();
        List<String> externalProductIds = new List<String>();

        for (OrderItem item : selectedOrderItems) {
            if (item.Product2.Is_External__c) {
                String productIdToUse = String.isNotBlank(item.Product2.External_Product_Id__c)
                    ? item.Product2.External_Product_Id__c
                    : item.Product2Id;
                externalProductIds.add(productIdToUse);
            } else {
                localOrderItems.add(item);
            }
        }

        Map<String, String> refundResponseData = new Map<String, String>();

        if (!externalProductIds.isEmpty()) {
            String externalCorrelationId = processExternalRefund(orderId, externalProductIds, refundType, description);
            refundResponseData.put('correlationId', externalCorrelationId);
        }

        if (!localOrderItems.isEmpty()) {
            Id localCaseId = processLocalRefund(orderId, localOrderItems, refundType, description);
            refundResponseData.put('localCaseId', localCaseId);
        }

        return JSON.serialize(refundResponseData);
    }

    private static String processExternalRefund(Id orderId, List<String> externalProductIds, String refundType, String description) {
        String correlationId = UUID.randomUUID().toString();

        String payloadData = JSON.serialize(
            new Map<String, String>{
                'Product_Ids__c' => String.join(externalProductIds, ','),
                'Reason__c' => refundType +
                ' - ' +
                description,
                'Case_Id__c' => correlationId,
                'Order_id__c' => String.valueOf(orderId)
            }
        );

        HttpRequest outboundRequest = new HttpRequest();
        outboundRequest.setEndpoint(Util.COMPLAINT.ENDPOINT_EXTERNAL_COMPLAINT);
        outboundRequest.setMethod('POST');
        outboundRequest.setHeader('Content-Type', 'application/json');
        outboundRequest.setBody(payloadData);

        ErrorLogger.logInfo(
            'OUTBOUND External_Complaint__e REQUEST | Payload: ' + payloadData,
            'RefundActionController',
            'processExternalRefund'
        );

        try {
            Http httpAgent = new Http();
            HttpResponse calloutResponse = httpAgent.send(outboundRequest);

            if (calloutResponse.getStatusCode() >= 200 && calloutResponse.getStatusCode() < 300) {
                ErrorLogger.logInfo(
                    'OUTBOUND External_Complaint__e SUCCESS | Status: ' +
                        calloutResponse.getStatusCode() +
                        ' | Response: ' +
                        calloutResponse.getBody(),
                    'RefundActionController',
                    'processExternalRefund'
                );
                return correlationId;
            } else {
                ErrorLogger.logWarning(
                    'OUTBOUND External_Complaint__e FAILED | Status: ' +
                        calloutResponse.getStatusCode() +
                        ' | Response: ' +
                        calloutResponse.getBody(),
                    'RefundActionController',
                    'processExternalRefund'
                );
                throw new AuraHandledException('Callout failed: ' + calloutResponse.getBody());
            }
        } catch (Exception calloutException) {
            ErrorLogger.logException(calloutException, 'RefundActionController', 'processExternalRefund');
            throw new AuraHandledException('Callout failed: ' + calloutException.getMessage());
        }
    }

    private static Id processLocalRefund(Id orderId, List<OrderItem> localOrderItems, String refundType, String description) {
        Case localRefundCase = new Case(
            Subject = Util.COMPLAINT.SUBJECT.LOCAL_REFUND + refundType,
            Description = description,
            Order__c = orderId,
            Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
            Requested_Refund_Type__c = refundType
        );
        insert localRefundCase;

        List<Case_Order_Product__c> caseProductsToInsert = new List<Case_Order_Product__c>();
        for (OrderItem localItem : localOrderItems) {
            caseProductsToInsert.add(
                new Case_Order_Product__c(
                    Case__c = localRefundCase.Id,
                    Order_Product__c = localItem.Id,
                    Name = localItem.Product2.Name,
                    Product_Name__c = localItem.Product2.Name,
                    Is_External__c = false
                )
            );
        }
        insert caseProductsToInsert;

        Order relatedOrder = new Order(Id = orderId, ComplaintCaseId__c = localRefundCase.Id);
        update relatedOrder;

        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
        approvalRequest.setObjectId(localRefundCase.Id);
        approvalRequest.setSubmitterId(UserInfo.getUserId());
        Approval.process(approvalRequest);

        return localRefundCase.Id;
    }
}
