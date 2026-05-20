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
        String result = RefundActionController.processRefund(testOrder.Id, new List<Id>{ localItem.Id }, 'Full', 'Test Reason', 100.00);
        Test.stopTest();

        Map<String, Object> parsedResult = (Map<String, Object>) JSON.deserializeUntyped(result);

        Assert.isTrue(parsedResult.containsKey('localCaseId'));
        Assert.isFalse(parsedResult.containsKey('correlationId'));

        Id caseId = (Id) parsedResult.get('localCaseId');
        Case insertedCase = [SELECT Id, Refund_Amount__c, Reason FROM Case WHERE Id = :caseId];
        Assert.isNotNull(insertedCase);
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
        String result = RefundActionController.processRefund(
            testOrder.Id,
            new List<Id>{ extItem.Id },
            'Partial',
            'Test Reason External',
            50.00
        );
        Test.stopTest();

        Map<String, Object> parsedResult = (Map<String, Object>) JSON.deserializeUntyped(result);

        Assert.isTrue(parsedResult.containsKey('correlationId'));
        Assert.isFalse(parsedResult.containsKey('localCaseId'));

        List<Case> localCases = [SELECT Id FROM Case];
        Assert.isTrue(localCases.isEmpty());
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
        String result = RefundActionController.processRefund(testOrder.Id, allItemIds, 'Partial', 'Mixed Request', 125.00);
        Test.stopTest();

        Map<String, Object> parsedResult = (Map<String, Object>) JSON.deserializeUntyped(result);

        Assert.isTrue(parsedResult.containsKey('localCaseId'));
        Assert.isTrue(parsedResult.containsKey('correlationId'));

        Id caseId = (Id) parsedResult.get('localCaseId');
        Case insertedCase = [SELECT Id, Refund_Amount__c, Reason FROM Case WHERE Id = :caseId];
        Assert.isNotNull(insertedCase);
        Assert.areEqual(125.00, insertedCase.Refund_Amount__c);
        Assert.areEqual('Partial - Mixed Request', insertedCase.Reason);

        Order updatedOrder = [SELECT Refund_Status__c FROM Order WHERE Id = :testOrder.Id];
        Assert.areEqual('Pending', updatedOrder.Refund_Status__c);
    }
}
