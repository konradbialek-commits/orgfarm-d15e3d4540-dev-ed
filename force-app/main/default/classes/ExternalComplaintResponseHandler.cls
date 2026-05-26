public class ExternalComplaintResponseHandler implements TriggerAction.AfterInsert {
    public class ResponseLineDTO {
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
            List<Order> ordersWithPending = [SELECT Id, Pending_Complaint_JSON__c FROM Order WHERE Pending_Complaint_JSON__c != NULL];
            List<Order> ordersToUpdate = new List<Order>();
            List<Case> casesToInsert = new List<Case>();
            Map<String, Order> correlationToOrder = new Map<String, Order>();
            Map<String, RefundActionController.PendingComplaint> correlationToPc = new Map<String, RefundActionController.PendingComplaint>();

            for (Order o : ordersWithPending) {
                try {
                    RefundActionController.PendingComplaint pc = (RefundActionController.PendingComplaint) JSON.deserialize(
                        o.Pending_Complaint_JSON__c,
                        RefundActionController.PendingComplaint.class
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
                RefundActionController.PendingComplaint pc = correlationToPc.get(corrId);

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
            for (String corrId : correlationToNewCase.keySet()) {
                Case insertedCase = correlationToNewCase.get(corrId);
                RefundActionController.PendingComplaint pc = correlationToPc.get(corrId);
                External_Complaint_Response__e resp = responseMap.get(corrId);
                Order o = correlationToOrder.get(corrId);

                Map<String, ResponseLineDTO> extIdToDto = new Map<String, ResponseLineDTO>();
                if (String.isNotBlank(resp.Line_Items_JSON__c)) {
                    List<ResponseLineDTO> respLines = (List<ResponseLineDTO>) JSON.deserialize(
                        resp.Line_Items_JSON__c,
                        List<ResponseLineDTO>.class
                    );
                    for (ResponseLineDTO rl : respLines) {
                        extIdToDto.put(rl.productId, rl);
                    }
                }

                for (RefundActionController.PendingLine pl : pc.lines) {
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

                    if (pl.isExternal && String.isNotBlank(pl.externalProductId) && extIdToDto.containsKey(pl.externalProductId)) {
                        ResponseLineDTO dto = extIdToDto.get(pl.externalProductId);
                        cop.Refund_Status__c = dto.status;
                        if (dto.refundAmount != null)
                            cop.Refund_Amount__c = dto.refundAmount;
                        if (String.isNotBlank(dto.refundType))
                            cop.Requested_Refund_Type__c = dto.refundType;
                    }

                    linesToInsert.add(cop);
                }

                o.Pending_Complaint_JSON__c = null;
                ordersToUpdate.add(o);
            }

            if (!linesToInsert.isEmpty()) {
                insert linesToInsert;

                List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
                for (Case_Order_Product__c cop : linesToInsert) {
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
                    List<ResponseLineDTO> items = (List<ResponseLineDTO>) JSON.deserialize(
                        eventRec.Line_Items_JSON__c,
                        List<ResponseLineDTO>.class
                    );
                    Map<String, ResponseLineDTO> extIdToDto = new Map<String, ResponseLineDTO>();
                    for (ResponseLineDTO item : items) {
                        extIdToDto.put(item.productId, item);
                    }

                    for (Case_Order_Product__c line : c.Case_Order_Products__r) {
                        if (String.isNotBlank(line.External_Product_Id__c) && extIdToDto.containsKey(line.External_Product_Id__c)) {
                            ResponseLineDTO dto = extIdToDto.get(line.External_Product_Id__c);
                            line.Refund_Status__c = dto.status;
                            if (dto.refundAmount != null)
                                line.Refund_Amount__c = dto.refundAmount;
                            if (String.isNotBlank(dto.refundType))
                                line.Requested_Refund_Type__c = dto.refundType;
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
