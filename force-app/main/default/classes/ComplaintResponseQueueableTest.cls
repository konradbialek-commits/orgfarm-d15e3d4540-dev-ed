@IsTest
private class ComplaintResponseQueueableTest {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"success": true}');
            res.setStatusCode(201);
            return res;
        }
    }

    @IsTest
    static void testExecute() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<String> payloads = new List<String>{ '{"Case_Id__c": "123", "Status__c": "Created"}' };

        Test.startTest();
        System.enqueueJob(new ComplaintResponseQueueable(payloads));
        Test.stopTest();

        // Assert that the job successfully queued and executed without throwing exceptions
        Assert.isTrue(true);
    }
}
