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

    @IsTest
    static void testInboundEventWithExternalProductId() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Product2 extProd = [SELECT Id, External_Product_Id__c, Name FROM Product2 WHERE Is_External__c = TRUE LIMIT 1];

        External_Complaint__e ev = TestDataFactory.createExternalComplaintEvent(
            '801x00000000000ZZZ',
            '500x00000000000DDD',
            'Full - Broken in transit',
            extProd.External_Product_Id__c
        );

        Test.startTest();
        new ExternalComplaintHandler().afterInsert(new List<SObject>{ ev });
        Test.stopTest();

        Case insertedCase = [
            SELECT Id, External_Case_Id__c
            FROM Case
            WHERE External_Case_Id__c = '500x00000000000DDD'
            LIMIT 1
        ];

        List<Case_Order_Product__c> copList = [
            SELECT Product_Name__c, Is_External__c
            FROM Case_Order_Product__c
            WHERE Case__c = :insertedCase.Id
        ];

        Assert.areEqual(1, copList.size());
        Assert.areEqual(extProd.Name, copList[0].Product_Name__c);
        Assert.isTrue(copList[0].Is_External__c);
    }
}
