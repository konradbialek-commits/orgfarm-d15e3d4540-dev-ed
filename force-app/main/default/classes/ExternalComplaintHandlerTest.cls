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
    }

    @IsTest
    static void testInboundEventWithExternalOrder() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        External_Complaint__e ev = new External_Complaint__e(
            Order_id__c = '801x00000000000ZZZ',
            Case_Id__c = '500x00000000000BBB',
            Reason__c = 'Partial - Missing parts',
            Product_Ids__c = '01tx00000000000BBB'
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
