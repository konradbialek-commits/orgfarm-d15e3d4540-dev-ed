@IsTest
private class ExternalComplaintHandlerTest {
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testInboundComplaintCreatesCaseAndResponse() {
        External_Complaint__e inboundEvent = new External_Complaint__e(
            Order_id__c = 'ORD-999',
            Case_Id__c = 'invalid-id-to-force-inbound',
            Reason__c = 'Item missing from package',
            Product_Ids__c = '01t000000000001'
        );

        Test.startTest();
        new ExternalComplaintHandler().afterInsert(new List<SObject>{ inboundEvent });
        Test.stopTest();

        List<Case> insertedCases = [SELECT Id, Subject, Description FROM Case];
        Assert.areEqual(1, insertedCases.size());
        Assert.isTrue(insertedCases[0].Subject.contains('External Refund Request'));
        Assert.isTrue(insertedCases[0].Description.contains('Item missing from package'));
        Assert.isTrue(insertedCases[0].Description.contains('01t000000000001'));
    }

    @IsTest
    static void testOutboundComplaintEnqueuesForwarder() {
        Case localCase = new Case(Subject = 'Local Refund Request');
        insert localCase;

        External_Complaint__e outboundEvent = new External_Complaint__e(
            Case_Id__c = String.valueOf(localCase.Id),
            Reason__c = 'User requested refund via LWC'
        );

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        new ExternalComplaintHandler().afterInsert(new List<SObject>{ outboundEvent });

        Assert.areEqual(1, Limits.getQueueableJobs());
        Test.stopTest();
    }
}
