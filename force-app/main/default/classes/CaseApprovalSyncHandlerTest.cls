@IsTest
private class CaseApprovalSyncHandlerTest {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true}');
            res.setStatusCode(201);
            return res;
        }
    }

    @IsTest
    static void testOrderSyncOnStatusChange() {
        Account acc = new Account(Name = 'Sync Test Account');
        insert acc;

        Order testOrder = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Refund_Status__c = 'Pending',
            Refunded_Amount__c = 0
        );
        insert testOrder;

        Case testCase = new Case(Subject = 'Refund Test', Order__c = testOrder.Id, Refund_Status__c = 'Pending', Refund_Amount__c = 50.00);
        insert testCase;

        Test.startTest();
        testCase.Refund_Status__c = 'Approved Partial Refund';
        update testCase;
        Test.stopTest();

        Order updatedOrder = [SELECT Refund_Status__c, Refunded_Amount__c FROM Order WHERE Id = :testOrder.Id];
        Assert.areEqual('Approved Partial Refund', updatedOrder.Refund_Status__c);
        Assert.areEqual(50.00, updatedOrder.Refunded_Amount__c);
    }

    @IsTest
    static void testExternalCaseApprovalSync() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Case testCase = new Case(
            Subject = 'External Refund Test',
            Order__c = null,
            External_Case_Id__c = 'Ext-123',
            Refund_Status__c = 'Pending',
            Refund_Amount__c = 50.00
        );
        insert testCase;

        Test.startTest();
        testCase.Refund_Status__c = 'Approved Full Refund';
        update testCase;
        Test.stopTest();

        Assert.areEqual('Approved Full Refund', [SELECT Refund_Status__c FROM Case WHERE Id = :testCase.Id].Refund_Status__c);
    }
}
