@IsTest
private class CaseApprovalSyncHandlerTest {
    @IsTest
    static void testOrderSyncOnStatusChange() {
        Account acc = new Account(Name = 'Sync Test Account');
        insert acc;

        Order testOrder = new Order(AccountId = acc.Id, EffectiveDate = Date.today(), Status = 'Draft', Refund_Status__c = 'Pending');
        insert testOrder;

        Case testCase = new Case(Subject = 'Refund Test', Order__c = testOrder.Id, Refund_Status__c = 'Pending');
        insert testCase;

        Test.startTest();
        testCase.Refund_Status__c = 'Full Refund';
        update testCase;
        Test.stopTest();

        Order updatedOrder = [SELECT Refund_Status__c FROM Order WHERE Id = :testOrder.Id];
        Assert.areEqual('Full Refund', updatedOrder.Refund_Status__c);
    }
}
