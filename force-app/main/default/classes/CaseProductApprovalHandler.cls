public class CaseProductApprovalHandler implements TriggerAction.AfterUpdate {
    public void afterUpdate(List<SObject> newList, List<SObject> oldList) {
        List<Case_Order_Product__c> newLines = (List<Case_Order_Product__c>) newList;
        List<Case_Order_Product__c> oldLines = (List<Case_Order_Product__c>) oldList;
        Set<Id> caseIds = new Set<Id>();

        for (Integer i = 0; i < newLines.size(); i++) {
            if (newLines[i].Refund_Status__c != oldLines[i].Refund_Status__c && newLines[i].Case__c != null) {
                caseIds.add(newLines[i].Case__c);
            }
        }

        if (caseIds.isEmpty())
            return;

        List<Case> casesToUpdate = new List<Case>();
        List<Order> ordersToUpdate = new List<Order>();

        for (Case c : [
            SELECT
                Id,
                CaseNumber,
                OwnerId,
                Order__c,
                Refund_Status__c,
                Refund_Amount__c,
                (SELECT Refund_Status__c, Refund_Amount__c FROM Case_Order_Products__r)
            FROM Case
            WHERE Id IN :caseIds
        ]) {
            Boolean hasPending = false;
            Boolean hasApproved = false;
            Boolean hasRejected = false;
            Decimal totalApproved = 0;

            for (Case_Order_Product__c line : c.Case_Order_Products__r) {
                if (line.Refund_Status__c == 'Pending')
                    hasPending = true;
                else if (
                    line.Refund_Status__c == 'Approved Full Refund' ||
                    line.Refund_Status__c == 'Approved Partial Refund' ||
                    line.Refund_Status__c == 'Approved'
                ) {
                    hasApproved = true;
                    totalApproved += (line.Refund_Amount__c != null ? line.Refund_Amount__c : 0);
                } else if (line.Refund_Status__c == 'Rejected')
                    hasRejected = true;
            }

            String newStatus = c.Refund_Status__c;
            if (hasPending) {
                newStatus = 'Pending';
            } else if (hasApproved && !hasRejected) {
                newStatus = 'Approved Full Refund';
            } else if (hasApproved && hasRejected) {
                newStatus = 'Approved Partial Refund';
            } else if (!hasApproved && hasRejected) {
                newStatus = 'Rejected';
            }

            if (c.Refund_Status__c != newStatus || c.Refund_Amount__c != totalApproved) {
                c.Refund_Status__c = newStatus;
                c.Refund_Amount__c = totalApproved;
                casesToUpdate.add(c);

                if (c.Order__c != null) {
                    ordersToUpdate.add(new Order(Id = c.Order__c, Refund_Status__c = newStatus, Refunded_Amount__c = totalApproved));
                }
            }
        }

        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
            NotificationUtil.sendStatusNotifications(casesToUpdate);
        }
        if (!ordersToUpdate.isEmpty()) {
            update ordersToUpdate;
        }
    }
}
