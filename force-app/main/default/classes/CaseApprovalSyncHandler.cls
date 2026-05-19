public class CaseApprovalSyncHandler implements TriggerAction.AfterUpdate {
    public void afterUpdate(List<SObject> newList, List<SObject> oldList) {
        List<Case> newCases = (List<Case>) newList;
        List<Case> oldCases = (List<Case>) oldList;

        Map<Id, Order> ordersToUpdate = new Map<Id, Order>();

        for (Integer i = 0; i < newCases.size(); i++) {
            Case newCase = newCases[i];
            Case oldCase = oldCases[i];

            if (newCase.Refund_Status__c != oldCase.Refund_Status__c && newCase.Order__c != null) {
                ordersToUpdate.put(newCase.Order__c, new Order(Id = newCase.Order__c, Refund_Status__c = newCase.Refund_Status__c));
            }
        }

        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate.values();
        }
    }
}
