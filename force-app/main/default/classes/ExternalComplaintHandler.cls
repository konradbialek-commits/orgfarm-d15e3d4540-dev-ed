public class ExternalComplaintHandler implements TriggerAction.AfterInsert {
    public void afterInsert(List<SObject> newList) {
        List<External_Complaint__e> incomingComplaints = (List<External_Complaint__e>) newList;

        Set<String> extractedProductIds = extractProductIds(incomingComplaints);
        Map<String, Product2> productByExternalOrLocalId = getProductMap(extractedProductIds);

        Map<Integer, External_Complaint__e> caseIndexToComplaintMap = new Map<Integer, External_Complaint__e>();
        List<Case> casesToCreate = buildComplaintCases(incomingComplaints, caseIndexToComplaintMap);

        if (!casesToCreate.isEmpty()) {
            insert casesToCreate;

            insertCaseProducts(casesToCreate, caseIndexToComplaintMap, productByExternalOrLocalId);
            submitCasesForApproval(casesToCreate);
            generateAndSendResponses(casesToCreate, caseIndexToComplaintMap);
        }
    }

    private Set<String> extractProductIds(List<External_Complaint__e> incomingComplaints) {
        Set<String> extractedProductIds = new Set<String>();
        for (External_Complaint__e complaint : incomingComplaints) {
            if (String.isNotBlank(complaint.Product_Ids__c)) {
                for (String productId : complaint.Product_Ids__c.split(',')) {
                    extractedProductIds.add(productId.trim());
                }
            }
        }
        return extractedProductIds;
    }

    private Map<String, Product2> getProductMap(Set<String> extractedProductIds) {
        Map<String, Product2> productByExternalOrLocalId = new Map<String, Product2>();

        if (extractedProductIds.isEmpty()) {
            return productByExternalOrLocalId;
        }

        Set<Id> validSalesforceIds = new Set<Id>();
        Set<String> externalIds = new Set<String>();

        for (String productId : extractedProductIds) {
            try {
                validSalesforceIds.add((Id) productId);
            } catch (Exception parseException) {
                ErrorLogger.logException(parseException, 'ExternalComplaintHandler', 'getProductMap');
            }
            externalIds.add(productId);
        }

        List<Product2> matchedProducts = [
            SELECT Id, Name, External_Product_Id__c, Is_External__c
            FROM Product2
            WHERE Id IN :validSalesforceIds OR External_Product_Id__c IN :externalIds
        ];

        for (Product2 productRecord : matchedProducts) {
            productByExternalOrLocalId.put(productRecord.Id, productRecord);
            if (String.isNotBlank(productRecord.External_Product_Id__c)) {
                productByExternalOrLocalId.put(productRecord.External_Product_Id__c, productRecord);
            }
        }

        return productByExternalOrLocalId;
    }

    private List<Case> buildComplaintCases(
        List<External_Complaint__e> incomingComplaints,
        Map<Integer, External_Complaint__e> caseIndexToComplaintMap
    ) {
        List<Case> casesToCreate = new List<Case>();

        for (External_Complaint__e complaint : incomingComplaints) {
            ErrorLogger.logInfo(
                'INBOUND EVENT RECEIVED | Type: External_Complaint__e | Payload: ' + JSON.serialize(complaint),
                'ExternalComplaintHandler',
                'buildComplaintCases'
            );

            String requestedRefundType = '';
            if (String.isNotBlank(complaint.Reason__c)) {
                if (complaint.Reason__c.startsWith(Util.COMPLAINT.TYPE.FULL)) {
                    requestedRefundType = Util.COMPLAINT.TYPE.FULL;
                } else if (complaint.Reason__c.startsWith(Util.COMPLAINT.TYPE.PARTIAL)) {
                    requestedRefundType = Util.COMPLAINT.TYPE.PARTIAL;
                }
            }

            Case newComplaintCase = new Case(
                Subject = Util.COMPLAINT.SUBJECT.EXTERNAL_REFUND,
                Reason = complaint.Reason__c,
                Order__c = null,
                Refund_Status__c = Util.COMPLAINT.STATUS.PENDING,
                Requested_Refund_Type__c = requestedRefundType,
                External_Case_Id__c = complaint.Case_Id__c,
                Refund_Amount__c = complaint.Refund_Amount__c
            );

            casesToCreate.add(newComplaintCase);
            caseIndexToComplaintMap.put(casesToCreate.size() - 1, complaint);
        }

        return casesToCreate;
    }

    private void insertCaseProducts(
        List<Case> insertedCases,
        Map<Integer, External_Complaint__e> caseIndexToComplaintMap,
        Map<String, Product2> productByExternalOrLocalId
    ) {
        List<Case_Order_Product__c> caseProductsToInsert = new List<Case_Order_Product__c>();

        for (Integer i = 0; i < insertedCases.size(); i++) {
            Case insertedCase = insertedCases[i];
            External_Complaint__e originalComplaint = caseIndexToComplaintMap.get(i);

            if (String.isNotBlank(originalComplaint.Product_Ids__c)) {
                for (String rawProductId : originalComplaint.Product_Ids__c.split(',')) {
                    String trimmedProductId = rawProductId.trim();
                    if (productByExternalOrLocalId.containsKey(trimmedProductId)) {
                        Product2 matchedProduct = productByExternalOrLocalId.get(trimmedProductId);
                        caseProductsToInsert.add(
                            new Case_Order_Product__c(
                                Case__c = insertedCase.Id,
                                Name = matchedProduct.Name,
                                Product_Name__c = matchedProduct.Name,
                                Is_External__c = matchedProduct.Is_External__c
                            )
                        );
                    }
                }
            }
        }

        if (!caseProductsToInsert.isEmpty()) {
            insert caseProductsToInsert;
        }
    }

    private void submitCasesForApproval(List<Case> casesToSubmit) {
        List<User> integrationUsers = [SELECT Id FROM User WHERE Name = 'Szymon Org User' AND IsActive = TRUE LIMIT 1];
        Id submitterId = integrationUsers.isEmpty() ? UserInfo.getUserId() : integrationUsers[0].Id;

        List<Approval.ProcessSubmitRequest> approvalRequests = new List<Approval.ProcessSubmitRequest>();
        for (Case complaintCase : casesToSubmit) {
            Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
            request.setObjectId(complaintCase.Id);
            request.setSubmitterId(submitterId);
            approvalRequests.add(request);
        }

        if (!approvalRequests.isEmpty()) {
            try {
                Approval.process(approvalRequests);
            } catch (Exception approvalException) {
                ErrorLogger.logException(approvalException, 'ExternalComplaintHandler', 'submitCasesForApproval');
            }
        }
    }

    private void generateAndSendResponses(List<Case> insertedCases, Map<Integer, External_Complaint__e> caseIndexToComplaintMap) {
        List<String> responsePayloads = new List<String>();

        for (Integer i = 0; i < insertedCases.size(); i++) {
            Case insertedCase = insertedCases[i];
            External_Complaint__e originalComplaint = caseIndexToComplaintMap.get(i);

            Map<String, String> responseBodyMap = new Map<String, String>{
                'Case_Id__c' => originalComplaint.Case_Id__c,
                'External_Case_Id__c' => String.valueOf(insertedCase.Id),
                'Status__c' => Util.COMPLAINT.RESPONSE_STATUS.CREATED
            };
            responsePayloads.add(JSON.serialize(responseBodyMap));
        }

        if (!responsePayloads.isEmpty() && !System.isQueueable() && !System.isBatch()) {
            System.enqueueJob(new ComplaintResponseQueueable(responsePayloads));
        }
    }
}
