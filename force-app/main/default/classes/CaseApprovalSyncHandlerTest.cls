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
    static void testLineItemRollupToCaseAndOrder() {
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

        Case testCase = new Case(Subject = 'Refund Test', Order__c = testOrder.Id, Refund_Status__c = 'Pending');
        insert testCase;

        Case_Order_Product__c cop1 = new Case_Order_Product__c(
            Case__c = testCase.Id,
            Refund_Status__c = 'Pending',
            Refund_Amount__c = 50.00
        );
        Case_Order_Product__c cop2 = new Case_Order_Product__c(
            Case__c = testCase.Id,
            Refund_Status__c = 'Pending',
            Refund_Amount__c = 25.00
        );
        insert new List<Case_Order_Product__c>{ cop1, cop2 };

        Test.startTest();
        cop1.Refund_Status__c = 'Approved Full Refund';
        cop2.Refund_Status__c = 'Rejected';
        update new List<Case_Order_Product__c>{ cop1, cop2 };
        Test.stopTest();

        Case updatedCase = [SELECT Refund_Status__c, Refund_Amount__c FROM Case WHERE Id = :testCase.Id];
        Assert.areEqual('Approved Partial Refund', updatedCase.Refund_Status__c);
        Assert.areEqual(50.00, updatedCase.Refund_Amount__c);

        Order updatedOrder = [SELECT Refund_Status__c, Refunded_Amount__c FROM Order WHERE Id = :testOrder.Id];
        Assert.areEqual('Approved Partial Refund', updatedOrder.Refund_Status__c);
        Assert.areEqual(50.00, updatedOrder.Refunded_Amount__c);
    }

    @IsTest
    static void testExternalCaseApprovalSyncOutbound() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Case testCase = new Case(
            Subject = 'External Refund Test',
            Order__c = null,
            External_Case_Id__c = 'Ext-123',
            Refund_Status__c = 'Pending'
        );
        insert testCase;

        Case_Order_Product__c cop1 = new Case_Order_Product__c(
            Case__c = testCase.Id,
            External_Product_Id__c = 'EXT-999',
            Refund_Status__c = 'Pending',
            Refund_Amount__c = 100.00,
            Requested_Refund_Type__c = 'Full'
        );
        insert cop1;

        Test.startTest();
        cop1.Refund_Status__c = 'Approved Full Refund';
        update cop1;
        Test.stopTest();

        Case updatedCase = [SELECT Refund_Status__c FROM Case WHERE Id = :testCase.Id];
        Assert.areEqual('Approved Full Refund', updatedCase.Refund_Status__c);
    }
}
