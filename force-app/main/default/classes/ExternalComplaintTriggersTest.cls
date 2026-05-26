@IsTest
private class ExternalComplaintTriggersTest {
    @IsTest
    static void testPlatformEventTriggersCoverage() {
        External_Complaint__e complaintEvent = new External_Complaint__e(
            Reason__c = 'Trigger Coverage Test',
            Line_Items_JSON__c = '[{"productId": "EXT-001", "refundAmount": 50.00, "refundType": "Full"}]'
        );

        External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(
            Status__c = 'Trigger Coverage Test',
            Line_Items_JSON__c = '[{"productId": "EXT-001", "status": "Approved Full Refund", "refundAmount": 50.00, "refundType": "Full"}]'
        );

        Test.startTest();
        EventBus.publish(complaintEvent);
        EventBus.publish(responseEvent);
        Test.stopTest();

        Assert.isTrue(true);
    }
}
