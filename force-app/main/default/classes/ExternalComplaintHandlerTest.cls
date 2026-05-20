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
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        Order testOrder = new Order(AccountId = testAcc.Id, Status = 'Draft', EffectiveDate = Date.today());
        insert testOrder;

        Product2 testProd1 = new Product2(Name = 'Ext Product 1', External_Product_Id__c = 'EXT-001', Is_External__c = true);
        Product2 testProd2 = new Product2(Name = 'Ext Product 2', Is_External__c = true);
        insert new List<Product2>{ testProd1, testProd2 };
    }

    @IsTest
    static void testInboundEventWithExternalOrder() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Product2 prod1 = [SELECT Id FROM Product2 WHERE External_Product_Id__c = 'EXT-001' LIMIT 1];
        Product2 prod2 = [SELECT Id FROM Product2 WHERE External_Product_Id__c = NULL LIMIT 1];

        External_Complaint__e ev = new External_Complaint__e(
            Order_id__c = '801x00000000000ZZZ',
            Case_Id__c = '500x00000000000BBB',
            Reason__c = 'Partial - Missing parts',
            Product_Ids__c = 'EXT-001,' + String.valueOf(prod2.Id) + ',INVALID-ID'
        );

        Test.startTest();
        new ExternalComplaintHandler().afterInsert(new List<SObject>{ ev });
        Test.stopTest();

        Case insertedCase = [
            SELECT Order__c, Requested_Refund_Type__c, External_Case_Id__c, Description
            FROM Case
            WHERE External_Case_Id__c = '500x00000000000BBB'
            LIMIT 1
        ];

        Assert.isNull(insertedCase.Order__c);
        Assert.areEqual('Partial', insertedCase.Requested_Refund_Type__c);
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
        External_Complaint__e ev = new External_Complaint__e(
            Order_id__c = 'INVALID_ID_FORMAT',
            Case_Id__c = '500x00000000000CCC',
            Reason__c = 'Full - Wrong item',
            Product_Ids__c = '01tx00000000000CCC'
        );

        Test.startTest();
        new ExternalComplaintHandler().afterInsert(new List<SObject>{ ev });
        Test.stopTest();

        Case insertedCase = [
            SELECT Order__c, Requested_Refund_Type__c, External_Case_Id__c, Description
            FROM Case
            WHERE External_Case_Id__c = '500x00000000000CCC'
            LIMIT 1
        ];

        Assert.isNull(insertedCase.Order__c);
        Assert.areEqual('Full', insertedCase.Requested_Refund_Type__c);
        Assert.isTrue(insertedCase.Description.contains('INVALID_ID_FORMAT'));
    }
}
