public class RefundActionController {
    public class RefundResponse {
        @AuraEnabled
        public String correlationId;
        @AuraEnabled
        public Id externalCaseId;
        @AuraEnabled
        public Id localCaseId;
    }

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
    public static RefundResponse processRefund(
        Id orderId,
        List<Id> orderItemIds,
        String refundType,
        String description,
        Decimal refundAmount
    ) {
        List<OrderItem> selectedOrderItems = [
            SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, Product2.Is_External__c, Product2.External_Product_Id__c
            FROM OrderItem
            WHERE Id IN :orderItemIds
        ];

        List<OrderItem> localOrderItems = new List<OrderItem>();
        List<OrderItem> externalOrderItems = new List<OrderItem>();
        List<String> externalProductIds = new List<String>();

        for (OrderItem item : selectedOrderItems) {
            if (item.Product2.Is_External__c) {
                String productIdToUse = String.isNotBlank(item.Product2.External_Product_Id__c)
                    ? item.Product2.External_Product_Id__c
                    : item.Product2Id;
                externalProductIds.add(productIdToUse);
                externalOrderItems.add(item);
            } else {
                localOrderItems.add(item);
            }
        }

        String correlationId = null;

        if (!externalProductIds.isEmpty()) {
            correlationId = UUID.randomUUID().toString();

            External_Complaint__e complaintEvent = new External_Complaint__e(
                Product_Ids__c = String.join(externalProductIds, ','),
                Reason__c = refundType + ' - ' + description,
                Case_Id__c = correlationId,
                Order_id__c = String.valueOf(orderId),
                Refund_Amount__c = refundAmount
            );

            HttpRequest outboundRequest = new HttpRequest();
            outboundRequest.setEndpoint(Util.COMPLAINT.ENDPOINT_EXTERNAL_COMPLAINT);
            outboundRequest.setMethod('POST');
            outboundRequest.setHeader('Content-Type', 'application/json');
            outboundRequest.setBody(JSON.serialize(complaintEvent));

            try {
                Http httpAgent = new Http();
                HttpResponse calloutResponse = httpAgent.send(outboundRequest);

                if (calloutResponse.getStatusCode() < 200 || calloutResponse.getStatusCode() >= 300) {
                    throw new AuraHandledException('Callout failed: ' + calloutResponse.getBody());
                }
            } catch (Exception calloutException) {
                ErrorLogger.logException(calloutException, 'RefundActionController', 'processRefund');
                throw new AuraHandledException('Callout failed: ' + calloutException.getMessage());
            }
        }

        List<Case> casesToInsert = new List<Case>();
        Case localCase = null;
        Case externalCase = null;

        if (!localOrderItems.isEmpty()) {
            localCase = new Case(
                Subject = Util.COMPLAINT.SUBJECT.LOCAL_REFUND + refundType,
                Reason = refundType + ' - ' + description,
                Order__c = orderId,
                Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                Requested_Refund_Type__c = refundType,
                Refund_Amount__c = refundAmount
            );
            casesToInsert.add(localCase);
        }

        if (!externalOrderItems.isEmpty()) {
            externalCase = new Case(
                Subject = Util.COMPLAINT.SUBJECT.EXTERNAL_REFUND,
                Reason = refundType + ' - ' + description,
                Order__c = orderId,
                Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                Requested_Refund_Type__c = refundType,
                Refund_Amount__c = refundAmount,
                External_Case_Id__c = correlationId
            );
            casesToInsert.add(externalCase);
        }

        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;
        }

        List<Case_Order_Product__c> caseProductsToInsert = new List<Case_Order_Product__c>();

        if (localCase != null) {
            for (OrderItem item : localOrderItems) {
                caseProductsToInsert.add(
                    new Case_Order_Product__c(
                        Case__c = localCase.Id,
                        Order_Product__c = item.Id,
                        Name = item.Product2.Name,
                        Product_Name__c = item.Product2.Name,
                        Is_External__c = false
                    )
                );
            }
        }

        if (externalCase != null) {
            for (OrderItem item : externalOrderItems) {
                caseProductsToInsert.add(
                    new Case_Order_Product__c(
                        Case__c = externalCase.Id,
                        Order_Product__c = item.Id,
                        Name = item.Product2.Name,
                        Product_Name__c = item.Product2.Name,
                        Is_External__c = true
                    )
                );
            }
        }

        if (!caseProductsToInsert.isEmpty()) {
            insert caseProductsToInsert;
        }

        if (localCase != null || externalCase != null) {
            Order relatedOrder = new Order(Id = orderId, Refund_Status__c = Util.COMPLAINT.STATUS.PENDING);
            update relatedOrder;
        }

        if (localCase != null) {
            Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
            approvalRequest.setObjectId(localCase.Id);
            approvalRequest.setSubmitterId(UserInfo.getUserId());
            Approval.process(approvalRequest);
        }

        RefundResponse responseData = new RefundResponse();
        responseData.correlationId = correlationId;
        if (localCase != null)
            responseData.localCaseId = localCase.Id;
        if (externalCase != null)
            responseData.externalCaseId = externalCase.Id;

        return responseData;
    }
}
