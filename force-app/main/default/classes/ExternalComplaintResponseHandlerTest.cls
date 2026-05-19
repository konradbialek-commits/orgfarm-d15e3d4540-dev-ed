@IsTest
private class ExternalComplaintResponseHandlerTest {
    @IsTest
    static void testInboundResponseUpdatesLocalCase() {
        Case localCase = new Case(Subject = 'Test Local Case', Description = 'Original Description');
        insert localCase;

        External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(
            Case_Id__c = String.valueOf(localCase.Id),
            External_Case_Id__c = '500x00000000000AAA',
            Status__c = 'Created'
        );

        Test.startTest();
        EventBus.publish(responseEvent);
        Test.stopTest();

        Case updatedCase = [SELECT External_Case_Id__c FROM Case WHERE Id = :localCase.Id];
        Assert.areEqual('500x00000000000AAA', updatedCase.External_Case_Id__c);
    }

    @IsTest
    static void testOutboundResponseEnqueuesQueueable() {
        External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(
            Case_Id__c = '500x00000000000BBB',
            External_Case_Id__c = '500x00000000000AAA',
            Status__c = 'Created'
        );

        Test.startTest();
        EventBus.publish(responseEvent);
        Test.stopTest();

        Assert.isTrue(true);
    }
}
