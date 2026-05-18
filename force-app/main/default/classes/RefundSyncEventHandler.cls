public class RefundSyncEventHandler implements TriggerAction.AfterInsert {
    public void afterInsert(List<SObject> newList) {
        List<Refund_Sync_Event__e> events = (List<Refund_Sync_Event__e>) newList;

        List<Case> casesToInsert = new List<Case>();
        Map<Integer, String> indexToCorrelationId = new Map<Integer, String>();
        Map<Integer, String> indexToSourceOrg = new Map<Integer, String>();

        for (Integer i = 0; i < events.size(); i++) {
            Refund_Sync_Event__e ev = events[i];

            if (ev.Action__c == 'REQUEST' && ev.Target_Org__c == 'YOUR_ORG_IDENTIFIER') {
                Case c = new Case(Subject = 'External Refund Request: ' + ev.Refund_Type__c, Description = ev.Description__c);
                casesToInsert.add(c);
                indexToCorrelationId.put(casesToInsert.size() - 1, ev.Correlation_Id__c);
                indexToSourceOrg.put(casesToInsert.size() - 1, ev.Target_Org__c);
            }
        }

        if (!casesToInsert.isEmpty()) {
            insert casesToInsert;

            List<Refund_Sync_Event__e> confirmations = new List<Refund_Sync_Event__e>();
            for (Integer i = 0; i < casesToInsert.size(); i++) {
                confirmations.add(
                    new Refund_Sync_Event__e(
                        Action__c = 'CONFIRMATION',
                        Correlation_Id__c = indexToCorrelationId.get(i),
                        Case_Id__c = casesToInsert[i].Id,
                        Target_Org__c = indexToSourceOrg.get(i)
                    )
                );
            }
            EventBus.publish(confirmations);
        }
    }
}
