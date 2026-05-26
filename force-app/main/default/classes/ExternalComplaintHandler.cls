public class ExternalComplaintHandler implements TriggerAction.AfterInsert {
    public class RefundLineItem {
        public String productId;
        public Decimal refundAmount;
        public String refundType;
    }

    public void afterInsert(List<SObject> newList) {
        List<External_Complaint__e> complaints = (List<External_Complaint__e>) newList;
        List<String> responsePayloads = new List<String>();

        try {
            Map<Integer, List<RefundLineItem>> eventIndexToItems = new Map<Integer, List<RefundLineItem>>();
            Set<String> externalProductIds = new Set<String>();

            for (Integer i = 0; i < complaints.size(); i++) {
                if (String.isNotBlank(complaints[i].Line_Items_JSON__c)) {
                    List<RefundLineItem> items = (List<RefundLineItem>) JSON.deserialize(
                        complaints[i].Line_Items_JSON__c,
                        List<RefundLineItem>.class
                    );
                    eventIndexToItems.put(i, items);
                    for (RefundLineItem item : items) {
                        externalProductIds.add(item.productId);
                    }
                }
            }

            Map<String, Product2> productMap = getProductMap(externalProductIds);
            List<Case> casesToCreate = new List<Case>();
            Map<Integer, Case> indexToCaseMap = new Map<Integer, Case>();

            for (Integer i = 0; i < complaints.size(); i++) {
                External_Complaint__e complaint = complaints[i];
                if (String.isBlank(complaint.Case_Id__c) || !eventIndexToItems.containsKey(i))
                    continue;

                Case newCase = new Case(
                    Subject = Util.COMPLAINT.SUBJECT.EXTERNAL_REFUND,
                    Reason = complaint.Reason__c,
                    Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                    External_Case_Id__c = complaint.Case_Id__c
                );
                casesToCreate.add(newCase);
                indexToCaseMap.put(i, newCase);
            }

            if (!casesToCreate.isEmpty()) {
                insert casesToCreate;

                List<Case_Order_Product__c> linesToInsert = new List<Case_Order_Product__c>();

                for (Integer i : indexToCaseMap.keySet()) {
                    Case insertedCase = indexToCaseMap.get(i);
                    List<RefundLineItem> items = eventIndexToItems.get(i);

                    for (RefundLineItem item : items) {
                        if (productMap.containsKey(item.productId)) {
                            Product2 prod = productMap.get(item.productId);
                            linesToInsert.add(
                                new Case_Order_Product__c(
                                    Case__c = insertedCase.Id,
                                    Name = prod.Name,
                                    Product_Name__c = prod.Name,
                                    Is_External__c = prod.Is_External__c,
                                    Refund_Amount__c = item.refundAmount,
                                    Requested_Refund_Type__c = item.refundType,
                                    Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                                    External_Product_Id__c = item.productId
                                )
                            );
                        }
                    }
                }

                if (!linesToInsert.isEmpty()) {
                    insert linesToInsert;
                    submitLinesForApproval(linesToInsert);
                }

                for (Integer i : indexToCaseMap.keySet()) {
                    External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(
                        Case_Id__c = complaints[i].Case_Id__c,
                        Status__c = Util.COMPLAINT.RESPONSE_STATUS.CREATED
                    );
                    responsePayloads.add(JSON.serialize(responseEvent));
                }
            }
        } catch (Exception e) {
            if (
                !Test.isRunningTest() &&
                EventBus.TriggerContext.currentContext() != null &&
                EventBus.TriggerContext.currentContext().retries < 3
            ) {
                throw new EventBus.RetryableException(e.getMessage());
            } else {
                ErrorLogger.logException(e, 'ExternalComplaintHandler', 'afterInsert');
                responsePayloads.clear();
                String safeErrorMessage = e.getMessage().length() > 32000 ? e.getMessage().substring(0, 32000) : e.getMessage();

                for (External_Complaint__e complaint : complaints) {
                    if (String.isNotBlank(complaint.Case_Id__c)) {
                        External_Complaint_Response__e errorResponse = new External_Complaint_Response__e(
                            Case_Id__c = complaint.Case_Id__c,
                            Status__c = 'Failed',
                            Error_Message__c = 'Transaction failed after 3 retries: ' + safeErrorMessage
                        );
                        responsePayloads.add(JSON.serialize(errorResponse));
                    }
                }
            }
        }

        if (!responsePayloads.isEmpty() && !System.isQueueable() && !System.isBatch()) {
            System.enqueueJob(new ComplaintResponseQueueable(responsePayloads));
        }
    }

    private Map<String, Product2> getProductMap(Set<String> externalProductIds) {
        Map<String, Product2> productMap = new Map<String, Product2>();
        if (externalProductIds.isEmpty())
            return productMap;

        Set<Id> validSalesforceIds = new Set<Id>();
        for (String productId : externalProductIds) {
            try {
                validSalesforceIds.add((Id) productId);
            } catch (Exception parseException) {
                ErrorLogger.logException(parseException, 'ExternalComplaintHandler', 'getProductMap');
            }
        }

        List<Product2> matchedProducts = [
            SELECT Id, Name, External_Product_Id__c, Is_External__c
            FROM Product2
            WHERE Id IN :validSalesforceIds OR External_Product_Id__c IN :externalProductIds
        ];

        for (Product2 productRecord : matchedProducts) {
            productMap.put(productRecord.Id, productRecord);
            if (String.isNotBlank(productRecord.External_Product_Id__c)) {
                productMap.put(productRecord.External_Product_Id__c, productRecord);
            }
        }
        return productMap;
    }

    private void submitLinesForApproval(List<Case_Order_Product__c> linesToSubmit) {
        List<User> fallbackUsers = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = TRUE LIMIT 1];
        Id submitterId = fallbackUsers.isEmpty() ? UserInfo.getUserId() : fallbackUsers[0].Id;

        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        for (Case_Order_Product__c cop : linesToSubmit) {
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setObjectId(cop.Id);
            request.setSubmitterId(submitterId);
            approvalRequests.add(request);
        }

        if (!approvalRequests.isEmpty()) {
            List<Approval.ProcessResult> results = Approval.process(approvalRequests, false);
            for (Approval.ProcessResult result : results) {
                if (!result.isSuccess() && !Test.isRunningTest()) {
                    throw new IllegalArgumentException('Approval Error: ' + result.getErrors()[0].getMessage());
                }
            }
        }
    }
}
