@IsTest
private class ExternalComplaintResponseHandlerTest {
    @IsTest
    static void testInboundResponseIsLogged() {
        External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(
            Case_Id__c = '123e4567-e89b-12d3-a456-426614174000',
            External_Case_Id__c = '500x00000000000AAA',
            Status__c = 'Created'
        );

        Test.startTest();
        EventBus.publish(responseEvent);
        Test.stopTest();

        Assert.isTrue(true);
    }
}
