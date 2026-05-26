@IsTest
private class ExternalComplaintResponseHandlerTest {
    @IsTest
    static void testInboundResponseUpdatesLineItems() {
        Case mockCase = new Case(
            Subject = 'Test Ext Case',
            External_Case_Id__c = '123e4567-e89b-12d3-a456-426614174000',
            Refund_Status__c = 'Pending'
        );
        insert mockCase;

        Case_Order_Product__c mockCop1 = new Case_Order_Product__c(
            Case__c = mockCase.Id,
            External_Product_Id__c = 'EXT-001',
            Refund_Status__c = 'Pending'
        );
        Case_Order_Product__c mockCop2 = new Case_Order_Product__c(
            Case__c = mockCase.Id,
            External_Product_Id__c = 'EXT-002',
            Refund_Status__c = 'Pending'
        );
        insert new List<Case_Order_Product__c>{ mockCop1, mockCop2 };

        List<Map<String, Object>> responseLines = new List<Map<String, Object>>{
            new Map<String, Object>{
                'productId' => 'EXT-001',
                'status' => 'Approved Partial Refund',
                'refundAmount' => 50.00,
                'refundType' => 'Partial'
            },
            new Map<String, Object>{ 'productId' => 'EXT-002', 'status' => 'Rejected', 'refundAmount' => 0.00, 'refundType' => 'Full' }
        };

        External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(
            Case_Id__c = '123e4567-e89b-12d3-a456-426614174000',
            Status__c = 'Approved Partial Refund',
            Line_Items_JSON__c = JSON.serialize(responseLines)
        );

        Test.startTest();
        EventBus.publish(responseEvent);
        Test.stopTest();

        Map<Id, Case_Order_Product__c> updatedCops = new Map<Id, Case_Order_Product__c>(
            [
                SELECT External_Product_Id__c, Refund_Status__c, Refund_Amount__c, Requested_Refund_Type__c
                FROM Case_Order_Product__c
                WHERE Case__c = :mockCase.Id
            ]
        );

        for (Case_Order_Product__c cop : updatedCops.values()) {
            if (cop.External_Product_Id__c == 'EXT-001') {
                Assert.areEqual('Approved Partial Refund', cop.Refund_Status__c);
                Assert.areEqual(50.00, cop.Refund_Amount__c);
                Assert.areEqual('Partial', cop.Requested_Refund_Type__c);
            } else if (cop.External_Product_Id__c == 'EXT-002') {
                Assert.areEqual('Rejected', cop.Refund_Status__c);
                Assert.areEqual(0.00, cop.Refund_Amount__c);
                Assert.areEqual('Full', cop.Requested_Refund_Type__c);
            }
        }
    }
}
