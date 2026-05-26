public class RefundActionController {
    public class RefundItem {
        public Id orderItemId;
        public String refundType;
        public Decimal refundAmount;
    }

    public class RefundResponse {
        @AuraEnabled
        public Id caseId;
        @AuraEnabled
        public Boolean hasExternalItems;
        @AuraEnabled
        public String correlationId;
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
    public static RefundResponse processRefund(Id orderId, String description, String refundItemsJSON) {
        List<RefundItem> items = (List<RefundItem>) JSON.deserialize(refundItemsJSON, List<RefundItem>.class);
        Set<Id> itemIds = new Set<Id>();
        Map<Id, RefundItem> refundItemMap = new Map<Id, RefundItem>();

        for (RefundItem i : items) {
            itemIds.add(i.orderItemId);
            refundItemMap.put(i.orderItemId, i);
        }

        List<OrderItem> selectedOrderItems = [
            SELECT Id, Product2Id, Product2.Name, Product2.ProductCode, Product2.Is_External__c, Product2.External_Product_Id__c
            FROM OrderItem
            WHERE Id IN :itemIds
        ];

        List<Case_Order_Product__c> caseProductsToInsert = new List<Case_Order_Product__c>();
        List<Map<String, Object>> externalLinesPayload = new List<Map<String, Object>>();
        Boolean hasExternal = false;
        String correlationId = UUID.randomUUID().toString();

        for (OrderItem oi : selectedOrderItems) {
            RefundItem ri = refundItemMap.get(oi.Id);
            if (oi.Product2.Is_External__c) {
                hasExternal = true;
                String extId = String.isNotBlank(oi.Product2.External_Product_Id__c) ? oi.Product2.External_Product_Id__c : oi.Product2Id;
                externalLinesPayload.add(
                    new Map<String, Object>{ 'productId' => extId, 'refundAmount' => ri.refundAmount, 'refundType' => ri.refundType }
                );
            }
        }

        if (hasExternal) {
            External_Complaint__e complaintEvent = new External_Complaint__e(
                Case_Id__c = correlationId,
                Order_id__c = String.valueOf(orderId),
                Reason__c = description,
                Line_Items_JSON__c = JSON.serialize(externalLinesPayload)
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

        Case singleCase = new Case(
            Subject = Util.COMPLAINT.SUBJECT.LOCAL_REFUND,
            Reason = description,
            Order__c = orderId,
            Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
            External_Case_Id__c = hasExternal ? correlationId : null
        );
        insert singleCase;

        for (OrderItem oi : selectedOrderItems) {
            RefundItem ri = refundItemMap.get(oi.Id);
            String extId = String.isNotBlank(oi.Product2.External_Product_Id__c) ? oi.Product2.External_Product_Id__c : oi.Product2Id;

            Case_Order_Product__c cop = new Case_Order_Product__c(
                Case__c = singleCase.Id,
                Order_Product__c = oi.Id,
                Name = oi.Product2.Name,
                Product_Name__c = oi.Product2.Name,
                Is_External__c = oi.Product2.Is_External__c,
                Refund_Amount__c = ri.refundAmount,
                Requested_Refund_Type__c = ri.refundType,
                Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                External_Product_Id__c = extId
            );
            caseProductsToInsert.add(cop);
        }

        insert caseProductsToInsert;

        Order relatedOrder = new Order(Id = orderId, Refund_Status__c = Util.COMPLAINT.STATUS.PENDING);
        update relatedOrder;

        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        for (Case_Order_Product__c cop : caseProductsToInsert) {
            if (!cop.Is_External__c) {
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setObjectId(cop.Id);
                req.setSubmitterId(UserInfo.getUserId());
                approvalRequests.add(req);
            }
        }

        if (!approvalRequests.isEmpty()) {
            Approval.process(approvalRequests, false);
        }

        RefundResponse res = new RefundResponse();
        res.caseId = singleCase.Id;
        res.hasExternalItems = hasExternal;
        res.correlationId = hasExternal ? correlationId : null;
        return res;
    }
}
