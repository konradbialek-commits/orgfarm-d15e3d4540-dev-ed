@IsTest
private class RefundActionControllerTest {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true}');
            res.setStatusCode(201);
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        Account testAcc = TestDataFactory.createAccount('Test Account');
        insert testAcc;

        Product2 localProd = TestDataFactory.createProduct('Local Product', null, false);
        Product2 extProd = TestDataFactory.createProduct('External Product', 'EP01', true);
        insert new List<Product2>{ localProd, extProd };

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbeLocal = TestDataFactory.createPricebookEntry(pricebookId, localProd.Id, 100);
        PricebookEntry pbeExt = TestDataFactory.createPricebookEntry(pricebookId, extProd.Id, 150);
        insert new List<PricebookEntry>{ pbeLocal, pbeExt };

        Order testOrder = TestDataFactory.createOrder(testAcc.Id, 'Draft', Date.today(), pricebookId);
        insert testOrder;

        OrderItem oiLocal = TestDataFactory.createOrderItem(testOrder.Id, pbeLocal.Id, 1, 100);
        OrderItem oiExt = TestDataFactory.createOrderItem(testOrder.Id, pbeExt.Id, 1, 150);
        insert new List<OrderItem>{ oiLocal, oiExt };
    }

    @IsTest
    static void testGetOrderItems() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];

        Test.startTest();
        List<OrderItem> items = RefundActionController.getOrderItems(testOrder.Id);
        Test.stopTest();

        Assert.areEqual(2, items.size());
    }

    @IsTest
    static void testProcessRefundLocalOnly() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        OrderItem localItem = [SELECT Id FROM OrderItem WHERE Product2.Is_External__c = FALSE LIMIT 1];

        Test.startTest();
        RefundActionController.RefundResponse result = RefundActionController.processRefund(
            testOrder.Id,
            new List<Id>{ localItem.Id },
            'Full',
            'Test Reason',
            100.00
        );
        Test.stopTest();

        Assert.isNotNull(result.localCaseId);
        Assert.isNull(result.correlationId);
        Assert.isNull(result.externalCaseId);

        Case insertedCase = [SELECT Id, Order__c, Refund_Amount__c, Reason FROM Case WHERE Id = :result.localCaseId];
        Assert.isNotNull(insertedCase);
        Assert.areEqual(testOrder.Id, insertedCase.Order__c);
        Assert.areEqual(100.00, insertedCase.Refund_Amount__c);
        Assert.areEqual('Full - Test Reason', insertedCase.Reason);

        Order updatedOrder = [SELECT Refund_Status__c FROM Order WHERE Id = :testOrder.Id];
        Assert.areEqual('Pending', updatedOrder.Refund_Status__c);
    }

    @IsTest
    static void testProcessRefundExternalOnly() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        OrderItem extItem = [SELECT Id FROM OrderItem WHERE Product2.Is_External__c = TRUE LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        RefundActionController.RefundResponse result = RefundActionController.processRefund(
            testOrder.Id,
            new List<Id>{ extItem.Id },
            'Partial',
            'Test Reason External',
            50.00
        );
        Test.stopTest();

        Assert.isNotNull(result.correlationId);
        Assert.isNotNull(result.externalCaseId);
        Assert.isNull(result.localCaseId);

        Case externalCase = [SELECT Id, Order__c, External_Case_Id__c, Reason FROM Case WHERE Id = :result.externalCaseId];
        Assert.isNotNull(externalCase);
        Assert.areEqual(testOrder.Id, externalCase.Order__c);
        Assert.areEqual('Partial - Test Reason External', externalCase.Reason);
        Assert.areEqual(result.correlationId, externalCase.External_Case_Id__c);

        Order updatedOrder = [SELECT Refund_Status__c FROM Order WHERE Id = :testOrder.Id];
        Assert.areEqual('Pending', updatedOrder.Refund_Status__c);
    }

    @IsTest
    static void testProcessRefundMixed() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        List<OrderItem> allItems = [SELECT Id FROM OrderItem];
        List<Id> allItemIds = new List<Id>();
        for (OrderItem oi : allItems) {
            allItemIds.add(oi.Id);
        }

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        RefundActionController.RefundResponse result = RefundActionController.processRefund(
            testOrder.Id,
            allItemIds,
            'Partial',
            'Mixed Request',
            125.00
        );
        Test.stopTest();

        Assert.isNotNull(result.localCaseId);
        Assert.isNotNull(result.correlationId);
        Assert.isNotNull(result.externalCaseId);
        Assert.areNotEqual(result.localCaseId, result.externalCaseId);

        List<Case> insertedCases = [
            SELECT Id, Order__c, Refund_Amount__c, Reason, External_Case_Id__c
            FROM Case
            WHERE Id IN (:result.localCaseId, :result.externalCaseId)
        ];
        Assert.areEqual(2, insertedCases.size());

        for (Case c : insertedCases) {
            Assert.areEqual(testOrder.Id, c.Order__c);
            Assert.areEqual(125.00, c.Refund_Amount__c);
            Assert.areEqual('Partial - Mixed Request', c.Reason);

            if (c.Id == result.externalCaseId) {
                Assert.isNotNull(c.External_Case_Id__c);
                Assert.areEqual(result.correlationId, c.External_Case_Id__c);
            } else {
                Assert.isNull(c.External_Case_Id__c);
            }
        }

        Order updatedOrder = [SELECT Refund_Status__c FROM Order WHERE Id = :testOrder.Id];
        Assert.areEqual('Pending', updatedOrder.Refund_Status__c);
    }
}
