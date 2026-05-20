@IsTest
private class ExternalComplaintHandlerTest {
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

        Order testOrder = TestDataFactory.createOrder(testAcc.Id, 'Draft', Date.today(), null);
        insert testOrder;

        Product2 testProd1 = TestDataFactory.createProduct('Ext Product 1', 'EXT-001', true);
        Product2 testProd2 = TestDataFactory.createProduct('Ext Product 2', null, true);
        insert new List<Product2>{ testProd1, testProd2 };
    }

    @IsTest
    static void testInboundEventWithExternalOrder() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Product2 prod1 = [SELECT Id FROM Product2 WHERE External_Product_Id__c = 'EXT-001' LIMIT 1];
        Product2 prod2 = [SELECT Id FROM Product2 WHERE External_Product_Id__c = NULL LIMIT 1];

        External_Complaint__e ev = TestDataFactory.createExternalComplaintEvent(
            '801x00000000000ZZZ',
            '500x00000000000BBB',
            'Partial - Missing parts',
            'EXT-001,' + String.valueOf(prod2.Id) + ',INVALID-ID',
            45.00
        );

        Test.startTest();
        new ExternalComplaintHandler().afterInsert(new List<SObject>{ ev });
        Test.stopTest();

        Case insertedCase = [
            SELECT Order__c, Requested_Refund_Type__c, External_Case_Id__c, Description, Refund_Amount__c
            FROM Case
            WHERE External_Case_Id__c = '500x00000000000BBB'
            LIMIT 1
        ];

        Assert.isNull(insertedCase.Order__c);
        Assert.areEqual('Partial', insertedCase.Requested_Refund_Type__c);
        Assert.areEqual(45.00, insertedCase.Refund_Amount__c);
        Assert.isTrue(insertedCase.Description.contains('801x00000000000ZZZ'));

        List<Case_Order_Product__c> copList = [
            SELECT Product_Name__c, Is_External__c
            FROM Case_Order_Product__c
            WHERE Case__c = :insertedCase.Id
        ];

        Assert.areEqual(2, copList.size());
    }

    @IsTest
    static void testInboundEventWithMalformedOrderId() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        External_Complaint__e ev = TestDataFactory.createExternalComplaintEvent(
            'INVALID_ID_FORMAT',
            '500x00000000000CCC',
            'Full - Wrong item',
            '01tx00000000000CCC',
            100.00
        );

        Test.startTest();
        new ExternalComplaintHandler().afterInsert(new List<SObject>{ ev });
        Test.stopTest();

        Case insertedCase = [
            SELECT Order__c, Requested_Refund_Type__c, External_Case_Id__c, Description, Refund_Amount__c
            FROM Case
            WHERE External_Case_Id__c = '500x00000000000CCC'
            LIMIT 1
        ];

        Assert.isNull(insertedCase.Order__c);
        Assert.areEqual('Full', insertedCase.Requested_Refund_Type__c);
        Assert.areEqual(100.00, insertedCase.Refund_Amount__c);
        Assert.isTrue(insertedCase.Description.contains('INVALID_ID_FORMAT'));
    }

    @IsTest
    static void testInboundEventWithExternalProductId() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Product2 extProd = [SELECT Id, External_Product_Id__c, Name FROM Product2 WHERE Is_External__c = TRUE LIMIT 1];

        External_Complaint__e ev = TestDataFactory.createExternalComplaintEvent(
            '801x00000000000ZZZ',
            '500x00000000000DDD',
            'Full - Broken in transit',
            extProd.External_Product_Id__c,
            200.00
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
