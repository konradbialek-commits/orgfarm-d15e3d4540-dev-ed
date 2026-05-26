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

        List<Map<String, Object>> lines = new List<Map<String, Object>>{
            new Map<String, Object>{ 'productId' => 'EXT-001', 'refundAmount' => 45.00, 'refundType' => 'Partial' },
            new Map<String, Object>{ 'productId' => String.valueOf(prod2.Id), 'refundAmount' => 10.00, 'refundType' => 'Full' }
        };

        External_Complaint__e ev = TestDataFactory.createExternalComplaintEvent(
            '801x00000000000ZZZ',
            '500x00000000000BBB',
            'Partial - Missing parts',
            JSON.serialize(lines)
        );

        Test.startTest();
        new ExternalComplaintHandler().afterInsert(new List<SObject>{ ev });
        Test.stopTest();

        Case insertedCase = [
            SELECT Order__c, External_Case_Id__c, Reason
            FROM Case
            WHERE External_Case_Id__c = '500x00000000000BBB'
            LIMIT 1
        ];

        Assert.isNull(insertedCase.Order__c);
        Assert.areEqual('Partial - Missing parts', insertedCase.Reason);

        List<Case_Order_Product__c> copList = [
            SELECT Product_Name__c, Is_External__c, Refund_Amount__c, Requested_Refund_Type__c
            FROM Case_Order_Product__c
            WHERE Case__c = :insertedCase.Id
        ];

        Assert.areEqual(2, copList.size());
    }

    @IsTest
    static void testInboundEventWithMalformedData() {
        External_Complaint__e malformedEvent = new External_Complaint__e(
            Line_Items_JSON__c = '[{"invalid": true]',
            Reason__c = 'Damaged',
            Case_Id__c = 'uuid-1234',
            Order_id__c = 'invalid-order-id-format'
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(malformedEvent);
        Test.stopTest();

        Assert.isTrue(sr.isSuccess());

        List<Case> insertedCases = [SELECT Id FROM Case WHERE External_Case_Id__c = 'uuid-1234'];
        Assert.areEqual(0, insertedCases.size());

        List<AsyncApexJob> queueableJobs = [
            SELECT Id
            FROM AsyncApexJob
            WHERE JobType = 'Queueable' AND ApexClass.Name = 'ComplaintResponseQueueable'
        ];
        Assert.areEqual(1, queueableJobs.size());
    }
}
