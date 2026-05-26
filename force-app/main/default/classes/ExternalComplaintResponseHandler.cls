public class ExternalComplaintResponseHandler implements TriggerAction.AfterInsert {
    public class RefundLineResponse {
        public String productId;
        public String status;
        public Decimal refundAmount;
        public String refundType;
    }

    public void afterInsert(List<SObject> newRecordsList) {
        try {
            List<External_Complaint_Response__e> responseEvents = (List<External_Complaint_Response__e>) newRecordsList;
            Map<String, External_Complaint_Response__e> correlationIdToResponseMap = new Map<String, External_Complaint_Response__e>();

            for (External_Complaint_Response__e responseEvent : responseEvents) {
                if (String.isNotBlank(responseEvent.Case_Id__c)) {
                    correlationIdToResponseMap.put(responseEvent.Case_Id__c, responseEvent);
                }
            }

            if (correlationIdToResponseMap.isEmpty())
                return;

            List<Order> ordersWithPendingComplaints = [
                SELECT Id, Pending_Complaint_JSON__c
                FROM Order
                WHERE Refund_Status__c = :Util.COMPLAINT.STATUS.PENDING
            ];
            List<Order> ordersToUpdate = new List<Order>();
            List<Case> casesToInsert = new List<Case>();
            Map<String, Order> correlationToOrder = new Map<String, Order>();
            Map<String, RefundActionService.PendingComplaint> correlationToPendingComplaint = new Map<String, RefundActionService.PendingComplaint>();

            for (Order pendingOrder : ordersWithPendingComplaints) {
                if (String.isBlank(pendingOrder.Pending_Complaint_JSON__c))
                    continue;
                try {
                    RefundActionService.PendingComplaint pendingComplaint = (RefundActionService.PendingComplaint) JSON.deserialize(
                        pendingOrder.Pending_Complaint_JSON__c,
                        RefundActionService.PendingComplaint.class
                    );
                    if (
                        String.isNotBlank(pendingComplaint.correlationId) &&
                        correlationIdToResponseMap.containsKey(pendingComplaint.correlationId)
                    ) {
                        correlationToOrder.put(pendingComplaint.correlationId, pendingOrder);
                        correlationToPendingComplaint.put(pendingComplaint.correlationId, pendingComplaint);
                    }
                } catch (Exception e) {
                    ErrorLogger.logException(e, 'ExternalComplaintResponseHandler', 'afterInsert');
                }
            }

            Map<String, Case> correlationToNewCase = new Map<String, Case>();
            for (String correlationId : correlationToOrder.keySet()) {
                External_Complaint_Response__e responseEvent = correlationIdToResponseMap.get(correlationId);
                Order pendingOrder = correlationToOrder.get(correlationId);
                RefundActionService.PendingComplaint pendingComplaint = correlationToPendingComplaint.get(correlationId);

                if (responseEvent.Status__c == Util.COMPLAINT.RESPONSE_STATUS.CREATED) {
                    Case newCase = new Case(
                        Subject = Util.COMPLAINT.SUBJECT.LOCAL_REFUND,
                        Reason = pendingComplaint.reason,
                        Order__c = pendingOrder.Id,
                        Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                        External_Case_Id__c = pendingComplaint.correlationId
                    );
                    casesToInsert.add(newCase);
                    correlationToNewCase.put(pendingComplaint.correlationId, newCase);
                } else if (responseEvent.Status__c == 'Failed' || responseEvent.Status__c == Util.COMPLAINT.STATUS.REJECTED) {
                    pendingOrder.Pending_Complaint_JSON__c = null;
                    pendingOrder.Refund_Status__c = Util.COMPLAINT.STATUS.REJECTED;
                    ordersToUpdate.add(pendingOrder);
                }
            }

            if (!casesToInsert.isEmpty()) {
                insert casesToInsert;
            }

            List<Case_Order_Product__c> caseProductsToInsert = new List<Case_Order_Product__c>();
            for (String correlationId : correlationToNewCase.keySet()) {
                Case insertedCase = correlationToNewCase.get(correlationId);
                RefundActionService.PendingComplaint pendingComplaint = correlationToPendingComplaint.get(correlationId);
                Order pendingOrder = correlationToOrder.get(correlationId);

                for (RefundActionService.PendingLine pendingLine : pendingComplaint.lines) {
                    Case_Order_Product__c caseProduct = new Case_Order_Product__c(
                        Case__c = insertedCase.Id,
                        Order_Product__c = pendingLine.orderItemId,
                        Name = pendingLine.productName,
                        Product_Name__c = pendingLine.productName,
                        Is_External__c = pendingLine.isExternal,
                        External_Product_Id__c = pendingLine.externalProductId,
                        Refund_Amount__c = pendingLine.refundAmount,
                        Requested_Refund_Type__c = pendingLine.refundType,
                        Refund_Status__c = Util.COMPLAINT.STATUS.PENDING
                    );
                    caseProductsToInsert.add(caseProduct);
                }

                pendingOrder.Pending_Complaint_JSON__c = null;
                ordersToUpdate.add(pendingOrder);
            }

            if (!caseProductsToInsert.isEmpty()) {
                insert caseProductsToInsert;

                for (Case insertedCase : correlationToNewCase.values()) {
                    Boolean hasLocalProducts = false;
                    for (Case_Order_Product__c caseProduct : caseProductsToInsert) {
                        if (caseProduct.Case__c == insertedCase.Id && !caseProduct.Is_External__c) {
                            hasLocalProducts = true;
                            break;
                        }
                    }

                    if (hasLocalProducts) {
                        Approval.ProcessSubmitRequest approvalRequest = new Approval.ProcessSubmitRequest();
                        approvalRequest.setObjectId(insertedCase.Id);
                        approvalRequest.setSubmitterId(UserInfo.getUserId());
                        Approval.ProcessResult result = Approval.process(approvalRequest, false);
                        if (!result.isSuccess() && !Test.isRunningTest()) {
                            ErrorLogger.logWarning(
                                'Approval Error: ' + result.getErrors()[0].getMessage(),
                                'ExternalComplaintResponseHandler',
                                'afterInsert'
                            );
                        }
                    }
                }
            }

            Set<String> subsequentCorrelationIds = new Set<String>();
            for (String correlationId : correlationIdToResponseMap.keySet()) {
                if (!correlationToNewCase.containsKey(correlationId)) {
                    subsequentCorrelationIds.add(correlationId);
                }
            }

            if (!subsequentCorrelationIds.isEmpty()) {
                List<Case> existingCases = [
                    SELECT
                        Id,
                        External_Case_Id__c,
                        (SELECT Id, External_Product_Id__c, Refund_Status__c, Is_External__c FROM Case_Order_Products__r)
                    FROM Case
                    WHERE External_Case_Id__c IN :subsequentCorrelationIds
                ];

                List<Case_Order_Product__c> caseProductsToUpdate = new List<Case_Order_Product__c>();
                Set<Id> caseIdsToEvaluate = new Set<Id>();

                for (Case existingCase : existingCases) {
                    External_Complaint_Response__e eventRecord = correlationIdToResponseMap.get(existingCase.External_Case_Id__c);

                    if (eventRecord.Status__c == 'Failed' || eventRecord.Status__c == Util.COMPLAINT.STATUS.REJECTED) {
                        for (Case_Order_Product__c caseProduct : existingCase.Case_Order_Products__r) {
                            if (caseProduct.Refund_Status__c == Util.COMPLAINT.STATUS.PENDING) {
                                caseProduct.Refund_Status__c = Util.COMPLAINT.STATUS.REJECTED;
                                caseProductsToUpdate.add(caseProduct);
                            }
                        }
                        caseIdsToEvaluate.add(existingCase.Id);
                        continue;
                    }

                    if (String.isNotBlank(eventRecord.Line_Items_JSON__c)) {
                        List<RefundLineResponse> responseItems = (List<RefundLineResponse>) JSON.deserialize(
                            eventRecord.Line_Items_JSON__c,
                            List<RefundLineResponse>.class
                        );
                        Map<String, RefundLineResponse> externalIdToResponseMap = new Map<String, RefundLineResponse>();
                        for (RefundLineResponse responseLine : responseItems) {
                            externalIdToResponseMap.put(responseLine.productId, responseLine);
                        }

                        for (Case_Order_Product__c caseProduct : existingCase.Case_Order_Products__r) {
                            if (
                                caseProduct.Is_External__c &&
                                String.isNotBlank(caseProduct.External_Product_Id__c) &&
                                externalIdToResponseMap.containsKey(caseProduct.External_Product_Id__c)
                            ) {
                                RefundLineResponse itemResponse = externalIdToResponseMap.get(caseProduct.External_Product_Id__c);
                                caseProduct.Refund_Status__c = itemResponse.status;
                                if (itemResponse.refundAmount != null)
                                    caseProduct.Refund_Amount__c = itemResponse.refundAmount;
                                if (String.isNotBlank(itemResponse.refundType))
                                    caseProduct.Requested_Refund_Type__c = itemResponse.refundType;
                                caseProductsToUpdate.add(caseProduct);
                            }
                        }
                        caseIdsToEvaluate.add(existingCase.Id);
                    }
                }

                if (!caseProductsToUpdate.isEmpty()) {
                    update caseProductsToUpdate;
                }

                for (Id caseId : caseIdsToEvaluate) {
                    RefundApprovalService.checkAndCompleteCaseApproval(caseId);
                }
            }

            if (!ordersToUpdate.isEmpty()) {
                update ordersToUpdate;
            }
        } catch (Exception e) {
            ErrorLogger.logException(e, 'ExternalComplaintResponseHandler', 'afterInsert');
        }
    }
}
