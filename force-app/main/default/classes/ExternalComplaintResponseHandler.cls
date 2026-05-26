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
            List<Case> casesToUpdate = [
                SELECT
                    Id,
                    CaseNumber,
                    OwnerId,
                    External_Case_Id__c,
                    Refund_Status__c,
                    (
                        SELECT Id, External_Product_Id__c, Refund_Status__c, Refund_Amount__c, Requested_Refund_Type__c
                        FROM Case_Order_Products__r
                    )
                FROM Case
                WHERE Id IN :responseMap.keySet() OR External_Case_Id__c IN :responseMap.keySet()
            ];

            List<Case_Order_Product__c> linesToUpdate = new List<Case_Order_Product__c>();

            for (Case c : casesToUpdate) {
                External_Complaint_Response__e eventRec = responseMap.containsKey(c.Id)
                    ? responseMap.get(c.Id)
                    : responseMap.get(c.External_Case_Id__c);

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
        }
    }
}
