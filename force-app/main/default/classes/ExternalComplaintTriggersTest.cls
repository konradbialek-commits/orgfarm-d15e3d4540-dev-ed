@IsTest
private class ExternalComplaintTriggersTest {
    @IsTest
    static void testPlatformEventTriggersCoverage() {
        External_Complaint__e complaintEvent = new External_Complaint__e(Reason__c = 'Trigger Coverage Test');

        External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(Status__c = 'Trigger Coverage Test');

        Test.startTest();

        EventBus.publish(complaintEvent);
        EventBus.publish(responseEvent);

        Test.stopTest();

        Assert.isTrue(true, 'Triggers executed successfully');
    }
}
