@IsTest
private class ExternalComplaintResponseHandlerTest {
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            return res;
        }
    }

    @IsTest
    static void testInboundResponseUpdatesLocalCase() {
        Case localCase = new Case(Subject = 'Awaiting External Sync', Description = 'Initial Desc');
        insert localCase;

        External_Complaint_Response__e inboundEvent = new External_Complaint_Response__e(
            Case_Id__c = String.valueOf(localCase.Id),
            External_Case_Id__c = 'REMOTE-CASE-555',
            Status__c = 'Created'
        );

        Test.startTest();
        new ExternalComplaintResponseHandler().afterInsert(new List<SObject>{ inboundEvent });
        Test.stopTest();

        Case updatedCase = [SELECT Description FROM Case WHERE Id = :localCase.Id];
        Assert.isTrue(updatedCase.Description.contains('REMOTE-CASE-555'));
        Assert.isTrue(updatedCase.Description.contains('Initial Desc'));
    }

    @IsTest
    static void testOutboundResponseEnqueuesForwarder() {
        External_Complaint_Response__e outboundEvent = new External_Complaint_Response__e(
            Case_Id__c = 'invalid-id-to-force-outbound',
            External_Case_Id__c = 'LOCAL-CASE-888',
            Status__c = 'Created'
        );

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();
        new ExternalComplaintResponseHandler().afterInsert(new List<SObject>{ outboundEvent });

        Assert.areEqual(1, Limits.getQueueableJobs());
        Test.stopTest();
    }
}
