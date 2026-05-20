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
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        Product2 localProd = new Product2(Name = 'Local Product', ProductCode = 'LP01', Is_External__c = false);
        Product2 extProd = new Product2(Name = 'External Product', ProductCode = 'EP01', Is_External__c = true);
        insert new List<Product2>{ localProd, extProd };

        Id pricebookId = Test.getStandardPricebookId();

        PricebookEntry pbeLocal = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = localProd.Id,
            UnitPrice = 100,
            IsActive = true
        );
        PricebookEntry pbeExt = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = extProd.Id, UnitPrice = 150, IsActive = true);
        insert new List<PricebookEntry>{ pbeLocal, pbeExt };

        Order testOrder = new Order(AccountId = testAcc.Id, Status = 'Draft', EffectiveDate = Date.today(), Pricebook2Id = pricebookId);
        insert testOrder;

        OrderItem oiLocal = new OrderItem(OrderId = testOrder.Id, PricebookEntryId = pbeLocal.Id, Quantity = 1, UnitPrice = 100);
        OrderItem oiExt = new OrderItem(OrderId = testOrder.Id, PricebookEntryId = pbeExt.Id, Quantity = 1, UnitPrice = 150);
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
        String result = RefundActionController.processRefund(testOrder.Id, new List<Id>{ localItem.Id }, 'Full', 'Test Reason');
        Test.stopTest();

        Map<String, Object> parsedResult = (Map<String, Object>) JSON.deserializeUntyped(result);

        Assert.isTrue(parsedResult.containsKey('localCaseId'));
        Assert.isFalse(parsedResult.containsKey('correlationId'));

        Id caseId = (Id) parsedResult.get('localCaseId');
        Case insertedCase = [SELECT Id FROM Case WHERE Id = :caseId];
        Assert.isNotNull(insertedCase);
    }

    @IsTest
    static void testProcessRefundExternalOnly() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        OrderItem extItem = [SELECT Id FROM OrderItem WHERE Product2.Is_External__c = TRUE LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        String result = RefundActionController.processRefund(testOrder.Id, new List<Id>{ extItem.Id }, 'Partial', 'Test Reason External');
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
        String result = RefundActionController.processRefund(testOrder.Id, allItemIds, 'Partial', 'Mixed Request');
        Test.stopTest();

        Map<String, Object> parsedResult = (Map<String, Object>) JSON.deserializeUntyped(result);

        Assert.isTrue(parsedResult.containsKey('localCaseId'));
        Assert.isTrue(parsedResult.containsKey('correlationId'));

        Id caseId = (Id) parsedResult.get('localCaseId');
        Case insertedCase = [SELECT Id FROM Case WHERE Id = :caseId];
        Assert.isNotNull(insertedCase);
    }
}
