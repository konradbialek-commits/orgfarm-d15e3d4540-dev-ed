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

        List<Map<String, Object>> itemsList = new List<Map<String, Object>>();
        itemsList.add(new Map<String, Object>{ 'orderItemId' => localItem.Id, 'refundType' => 'Full', 'refundAmount' => 100.00 });

        Test.startTest();
        RefundActionController.RefundResponse result = RefundActionController.processRefund(
            testOrder.Id,
            'Test Reason',
            JSON.serialize(itemsList)
        );
        Test.stopTest();

        Assert.isNotNull(result.caseId);
        Assert.isFalse(result.hasExternalItems);
        Assert.isNull(result.correlationId);

        Case insertedCase = [SELECT Id, Order__c, Reason FROM Case WHERE Id = :result.caseId];
        Assert.isNotNull(insertedCase);
        Assert.areEqual(testOrder.Id, insertedCase.Order__c);
        Assert.areEqual('Test Reason', insertedCase.Reason);

        List<Case_Order_Product__c> cops = [
            SELECT Refund_Amount__c, Requested_Refund_Type__c
            FROM Case_Order_Product__c
            WHERE Case__c = :result.caseId
        ];
        Assert.areEqual(1, cops.size());
        Assert.areEqual(100.00, cops[0].Refund_Amount__c);
        Assert.areEqual('Full', cops[0].Requested_Refund_Type__c);
    }

    @IsTest
    static void testProcessRefundExternalOnly() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        OrderItem extItem = [SELECT Id FROM OrderItem WHERE Product2.Is_External__c = TRUE LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Map<String, Object>> itemsList = new List<Map<String, Object>>();
        itemsList.add(new Map<String, Object>{ 'orderItemId' => extItem.Id, 'refundType' => 'Partial', 'refundAmount' => 50.00 });

        Test.startTest();
        RefundActionController.RefundResponse result = RefundActionController.processRefund(
            testOrder.Id,
            'Test Reason External',
            JSON.serialize(itemsList)
        );
        Test.stopTest();

        Assert.isNull(result.caseId);
        Assert.isTrue(result.hasExternalItems);
        Assert.isNotNull(result.correlationId);

        Order updatedOrder = [SELECT Pending_Complaint_JSON__c FROM Order WHERE Id = :testOrder.Id];
        Assert.isNotNull(updatedOrder.Pending_Complaint_JSON__c);
    }

    @IsTest
    static void testProcessRefundMixed() {
        Order testOrder = [SELECT Id FROM Order LIMIT 1];
        List<OrderItem> allItems = [SELECT Id, Product2.Is_External__c FROM OrderItem];

        List<Map<String, Object>> itemsList = new List<Map<String, Object>>();
        for (OrderItem oi : allItems) {
            itemsList.add(
                new Map<String, Object>{
                    'orderItemId' => oi.Id,
                    'refundType' => oi.Product2.Is_External__c ? 'Full' : 'Partial',
                    'refundAmount' => oi.Product2.Is_External__c ? 150.00 : 25.00
                }
            );
        }

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        RefundActionController.RefundResponse result = RefundActionController.processRefund(
            testOrder.Id,
            'Mixed Request',
            JSON.serialize(itemsList)
        );
        Test.stopTest();

        Assert.isNull(result.caseId);
        Assert.isTrue(result.hasExternalItems);
        Assert.isNotNull(result.correlationId);

        Order updatedOrder = [SELECT Pending_Complaint_JSON__c FROM Order WHERE Id = :testOrder.Id];
        Assert.isNotNull(updatedOrder.Pending_Complaint_JSON__c);
    }
}
