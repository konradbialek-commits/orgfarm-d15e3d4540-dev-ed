public class ExternalComplaintResponseHandler implements TriggerAction.AfterInsert {
    public class RefundLineResponse {
        public String productId;
        public String status;
        public Decimal refundAmount;
        public String refundType;
    }

    public void afterInsert(List<SObject> newList) {
        List<External_Complaint_Response__e> responses = (List<External_Complaint_Response__e>) newList;
        Map<String, External_Complaint_Response__e> responseMap = new Map<String, External_Complaint_Response__e>();

        for (External_Complaint_Response__e response : responses) {
            if (String.isNotBlank(response.Case_Id__c)) {
                responseMap.put(response.Case_Id__c, response);
            }
        }

        if (!responseMap.isEmpty()) {
            List<Order> ordersWithPending = [SELECT Id, Pending_Complaint_JSON__c FROM Order WHERE Refund_Status__c = 'Pending'];
            List<Order> ordersToUpdate = new List<Order>();
            List<Case> casesToInsert = new List<Case>();
            Map<String, Order> correlationToOrder = new Map<String, Order>();
            Map<String, RefundActionService.PendingComplaint> correlationToPc = new Map<String, RefundActionService.PendingComplaint>();

            for (Order o : ordersWithPending) {
                if (String.isBlank(o.Pending_Complaint_JSON__c)) {
                    continue;
                }
                try {
                    RefundActionService.PendingComplaint pc = (RefundActionService.PendingComplaint) JSON.deserialize(
                        o.Pending_Complaint_JSON__c,
                        RefundActionService.PendingComplaint.class
                    );
                    if (String.isNotBlank(pc.correlationId) && responseMap.containsKey(pc.correlationId)) {
                        correlationToOrder.put(pc.correlationId, o);
                        correlationToPc.put(pc.correlationId, pc);
                    }
                } catch (Exception e) {
                }
            }

            Map<String, Case> correlationToNewCase = new Map<String, Case>();
            for (String corrId : correlationToOrder.keySet()) {
                External_Complaint_Response__e resp = responseMap.get(corrId);
                Order o = correlationToOrder.get(corrId);
                RefundActionService.PendingComplaint pc = correlationToPc.get(corrId);

                if (resp.Status__c == 'Failed') {
                    o.Pending_Complaint_JSON__c = null;
                    o.Refund_Status__c = 'Rejected';
                    ordersToUpdate.add(o);
                } else {
                    Case newCase = new Case(
                        Subject = Util.COMPLAINT.SUBJECT.LOCAL_REFUND,
                        Reason = pc.reason,
                        Order__c = o.Id,
                        Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                        External_Case_Id__c = pc.correlationId
                    );
                    casesToInsert.add(newCase);
                    correlationToNewCase.put(pc.correlationId, newCase);
                }
            }

            if (!casesToInsert.isEmpty()) {
                insert casesToInsert;
            }

            List<Case_Order_Product__c> linesToInsert = new List<Case_Order_Product__c>();
            List<Case> casesToSubmit = new List<Case>();

            for (String corrId : correlationToNewCase.keySet()) {
                Case insertedCase = correlationToNewCase.get(corrId);
                RefundActionService.PendingComplaint pc = correlationToPc.get(corrId);
                External_Complaint_Response__e resp = responseMap.get(corrId);
                Order o = correlationToOrder.get(corrId);

                Map<String, RefundLineResponse> extIdToResponse = new Map<String, RefundLineResponse>();
                if (String.isNotBlank(resp.Line_Items_JSON__c)) {
                    List<RefundLineResponse> respLines = (List<RefundLineResponse>) JSON.deserialize(
                        resp.Line_Items_JSON__c,
                        List<RefundLineResponse>.class
                    );
                    for (RefundLineResponse rl : respLines) {
                        extIdToResponse.put(rl.productId, rl);
                    }
                }

                for (RefundActionService.PendingLine pl : pc.lines) {
                    Case_Order_Product__c cop = new Case_Order_Product__c(
                        Case__c = insertedCase.Id,
                        Order_Product__c = pl.orderItemId,
                        Name = pl.productName,
                        Product_Name__c = pl.productName,
                        Is_External__c = pl.isExternal,
                        External_Product_Id__c = pl.externalProductId,
                        Refund_Amount__c = pl.refundAmount,
                        Requested_Refund_Type__c = pl.refundType,
                        Refund_Status__c = Util.COMPLAINT.STATUS.PENDING
                    );

                    if (pl.isExternal && String.isNotBlank(pl.externalProductId) && extIdToResponse.containsKey(pl.externalProductId)) {
                        RefundLineResponse itemResponse = extIdToResponse.get(pl.externalProductId);
                        cop.Refund_Status__c = itemResponse.status;
                        if (itemResponse.refundAmount != null)
                            cop.Refund_Amount__c = itemResponse.refundAmount;
                        if (String.isNotBlank(itemResponse.refundType))
                            cop.Requested_Refund_Type__c = itemResponse.refundType;
                    }

                    linesToInsert.add(cop);
                }

                casesToSubmit.add(insertedCase);

                o.Pending_Complaint_JSON__c = null;
                ordersToUpdate.add(o);
            }

            if (!linesToInsert.isEmpty()) {
                insert linesToInsert;

                for (Case insertedCase : casesToSubmit) {
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setObjectId(insertedCase.Id);
                    req.setSubmitterId(UserInfo.getUserId());
                    Approval.ProcessResult result = Approval.process(req, false);
                    if (!result.isSuccess() && !Test.isRunningTest()) {
                        ErrorLogger.logWarning(
                            'Approval Error: ' + result.getErrors()[0].getMessage(),
                            'ExternalComplaintResponseHandler',
                            'afterInsert'
                        );
                    }
                }
            }

            List<Case> existingCases = [
                SELECT Id, External_Case_Id__c, (SELECT Id, External_Product_Id__c, Refund_Status__c FROM Case_Order_Products__r)
                FROM Case
                WHERE External_Case_Id__c IN :responseMap.keySet()
            ];

            List<Case_Order_Product__c> linesToUpdate = new List<Case_Order_Product__c>();

            for (Case c : existingCases) {
                External_Complaint_Response__e eventRec = responseMap.get(c.External_Case_Id__c);

                if (eventRec.Status__c == 'Failed') {
                    for (Case_Order_Product__c line : c.Case_Order_Products__r) {
                        line.Refund_Status__c = 'Rejected';
                        linesToUpdate.add(line);
                    }
                    continue;
                }

                if (String.isNotBlank(eventRec.Line_Items_JSON__c)) {
                    List<RefundLineResponse> items = (List<RefundLineResponse>) JSON.deserialize(
                        eventRec.Line_Items_JSON__c,
                        List<RefundLineResponse>.class
                    );
                    Map<String, RefundLineResponse> extIdToResponse = new Map<String, RefundLineResponse>();
                    for (RefundLineResponse item : items) {
                        extIdToResponse.put(item.productId, item);
                    }

                    for (Case_Order_Product__c line : c.Case_Order_Products__r) {
                        if (String.isNotBlank(line.External_Product_Id__c) && extIdToResponse.containsKey(line.External_Product_Id__c)) {
                            RefundLineResponse itemResponse = extIdToResponse.get(line.External_Product_Id__c);
                            line.Refund_Status__c = itemResponse.status;
                            if (itemResponse.refundAmount != null)
                                line.Refund_Amount__c = itemResponse.refundAmount;
                            if (String.isNotBlank(itemResponse.refundType))
                                line.Requested_Refund_Type__c = itemResponse.refundType;
                            linesToUpdate.add(line);
                        }
                    }
                }
            }

            if (!linesToUpdate.isEmpty()) {
                update linesToUpdate;
            }

            if (!ordersToUpdate.isEmpty()) {
                update ordersToUpdate;
            }
        }
    }
}
