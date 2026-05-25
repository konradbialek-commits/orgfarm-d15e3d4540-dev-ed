public class CaseApprovalSyncHandler implements TriggerAction.AfterUpdate {
    public void afterUpdate(List<SObject> newList, List<SObject> oldList) {
        List<Case> newCases = (List<Case>) newList;
        List<Case> oldCases = (List<Case>) oldList;

        Set<Id> orderIds = new Set<Id>();
        List<String> outboundResponses = new List<String>();

        for (Integer i = 0; i < newCases.size(); i++) {
            Case newCase = newCases[i];
            Case oldCase = oldCases[i];

            if (newCase.Refund_Status__c != oldCase.Refund_Status__c) {
                if (newCase.Order__c != null) {
                    orderIds.add(newCase.Order__c);
                }

                if (newCase.Order__c == null && String.isNotBlank(newCase.External_Case_Id__c)) {
                    if (
                        newCase.Refund_Status__c == Util.COMPLAINT.STATUS.APPROVED_FULL ||
                        newCase.Refund_Status__c == Util.COMPLAINT.StATUS.APPROVED_PARTIAL ||
                        newCase.Refund_Status__c == Util.COMPLAINT.STATUS.REJECTED
                    ) {
                        External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(
                            Case_Id__c = newCase.External_Case_Id__c,
                            Status__c = newCase.Refund_Status__c,
                            Final_Refund_Amount__c = newCase.Refund_Amount__c,
                            Final_Refund_Type__c = newCase.Requested_Refund_Type__c
                        );
                        outboundResponses.add(JSON.serialize(responseEvent));
                    }
                }
            }
        }

        if (!outboundResponses.isEmpty() && !System.isBatch() && !System.isQueueable()) {
            System.enqueueJob(new ComplaintResponseQueueable(outboundResponses));
        }

        if (orderIds.isEmpty())
            return;

        Map<Id, Order> orderMap = new Map<Id, Order>(
            [
                SELECT Id, Refund_Status__c, Refunded_Amount__c
                FROM Order
                WHERE Id IN :orderIds
            ]
        );

        Map<Id, Order> ordersToUpdate = new Map<Id, Order>();

        for (Integer i = 0; i < newCases.size(); i++) {
            Case newCase = newCases[i];
            Case oldCase = oldCases[i];

            if (newCase.Refund_Status__c != oldCase.Refund_Status__c && newCase.Order__c != null) {
                Order relOrder = ordersToUpdate.containsKey(newCase.Order__c)
                    ? ordersToUpdate.get(newCase.Order__c)
                    : orderMap.get(newCase.Order__c);

                relOrder.Refund_Status__c = newCase.Refund_Status__c;

                if (
                    newCase.Refund_Status__c == Util.COMPLAINT.STATUS.APPROVED_FULL ||
                    newCase.Refund_Status__c == Util.COMPLAINT.StATUS.APPROVED_PARTIAL
                ) {
                    Decimal currentRefund = relOrder.Refunded_Amount__c != null ? relOrder.Refunded_Amount__c : 0;
                    Decimal newRefund = newCase.Refund_Amount__c != null ? newCase.Refund_Amount__c : 0;
                    relOrder.Refunded_Amount__c = currentRefund + newRefund;
                }

                ordersToUpdate.put(relOrder.Id, relOrder);
            }
        }

        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate.values();
        }
    }
}
