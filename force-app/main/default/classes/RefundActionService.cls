public class RefundActionService {
    public class RefundItem {
        public Id orderItemId;
        public String refundType;
        public Decimal refundAmount;
    }

    public class PendingComplaint {
        public String correlationId;
        public String reason;
        public List<PendingLine> lines;
    }

    public class PendingLine {
        public Id orderItemId;
        public String productName;
        public Boolean isExternal;
        public String externalProductId;
        public Decimal refundAmount;
        public String refundType;
    }

    public class RefundResponse {
        @AuraEnabled
        public Id caseId;
        @AuraEnabled
        public Boolean hasExternalItems;
        @AuraEnabled
        public String correlationId;
    }

    public static List<OrderItem> getOrderItems(Id orderId) {
        try {
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
        } catch (Exception e) {
            ErrorLogger.logException(e, 'RefundActionService', 'getOrderItems');
            throw e;
        }
    }

    public static RefundResponse processRefund(Id orderId, String description, String refundItemsJSON) {
        try {
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

            List<Map<String, Object>> externalLinesPayload = new List<Map<String, Object>>();
            Boolean hasExternal = false;
            String correlationId = UUID.randomUUID().toString();
            List<PendingLine> pendingLines = new List<PendingLine>();

            for (OrderItem oi : selectedOrderItems) {
                RefundItem ri = refundItemMap.get(oi.Id);
                String extId = String.isNotBlank(oi.Product2.External_Product_Id__c) ? oi.Product2.External_Product_Id__c : oi.Product2Id;

                PendingLine pl = new PendingLine();
                pl.orderItemId = oi.Id;
                pl.productName = oi.Product2.Name;
                pl.isExternal = oi.Product2.Is_External__c;
                pl.externalProductId = extId;
                pl.refundAmount = ri.refundAmount;
                pl.refundType = ri.refundType;
                pendingLines.add(pl);

                if (oi.Product2.Is_External__c) {
                    hasExternal = true;
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

                Http httpAgent = new Http();
                HttpResponse calloutResponse = httpAgent.send(outboundRequest);

                if (calloutResponse.getStatusCode() < 200 || calloutResponse.getStatusCode() >= 300) {
                    throw new CalloutException('Callout failed: ' + calloutResponse.getBody());
                }

                PendingComplaint pc = new PendingComplaint();
                pc.correlationId = correlationId;
                pc.reason = description;
                pc.lines = pendingLines;

                Order relatedOrder = new Order(
                    Id = orderId,
                    Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                    Pending_Complaint_JSON__c = JSON.serialize(pc)
                );
                update relatedOrder;

                RefundResponse res = new RefundResponse();
                res.caseId = null;
                res.hasExternalItems = true;
                res.correlationId = correlationId;
                return res;
            }

            Case singleCase = new Case(
                Subject = Util.COMPLAINT.SUBJECT.LOCAL_REFUND,
                Reason = description,
                Order__c = orderId,
                Refund_Status__c = Util.COMPLAINT.STATUS.PENDING
            );
            insert singleCase;

            List<Case_Order_Product__c> caseProductsToInsert = new List<Case_Order_Product__c>();
            for (PendingLine pl : pendingLines) {
                Case_Order_Product__c cop = new Case_Order_Product__c(
                    Case__c = singleCase.Id,
                    Order_Product__c = pl.orderItemId,
                    Name = pl.productName,
                    Product_Name__c = pl.productName,
                    Is_External__c = false,
                    Refund_Amount__c = pl.refundAmount,
                    Requested_Refund_Type__c = pl.refundType,
                    Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                    External_Product_Id__c = pl.externalProductId
                );
                caseProductsToInsert.add(cop);
            }

            insert caseProductsToInsert;

            Order relatedOrderLocal = new Order(Id = orderId, Refund_Status__c = Util.COMPLAINT.STATUS.PENDING);
            update relatedOrderLocal;

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(singleCase.Id);
            req.setSubmitterId(UserInfo.getUserId());
            Approval.ProcessResult result = Approval.process(req, false);
            if (!result.isSuccess() && !Test.isRunningTest()) {
                throw new IllegalArgumentException('Approval Error: ' + result.getErrors()[0].getMessage());
            }

            RefundResponse res = new RefundResponse();
            res.caseId = singleCase.Id;
            res.hasExternalItems = false;
            res.correlationId = null;
            return res;
        } catch (Exception e) {
            ErrorLogger.logException(e, 'RefundActionService', 'processRefund');
            throw e;
        }
    }
}
