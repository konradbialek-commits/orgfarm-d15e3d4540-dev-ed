@IsTest
private class ExternalComplaintResponseHandlerTest {
    @IsTest
    static void testInboundResponseUpdatesCaseStatusAmountAndType() {
        Case mockCase = new Case(
            Subject = 'Test Ext Case',
            External_Case_Id__c = '123e4567-e89b-12d3-a456-426614174000',
            Refund_Status__c = 'Pending',
            Refund_Amount__c = 100.00,
            Requested_Refund_Type__c = 'Full'
        );
        insert mockCase;

        External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(
            Case_Id__c = '123e4567-e89b-12d3-a456-426614174000',
            Status__c = 'Approved Partial Refund',
            Final_Refund_Amount__c = 50.00,
            Final_Refund_Type__c = 'Partial'
        );

        Test.startTest();
        EventBus.publish(responseEvent);
        Test.stopTest();

        Case updatedCase = [SELECT Refund_Status__c, Refund_Amount__c, Requested_Refund_Type__c FROM Case WHERE Id = :mockCase.Id];
        Assert.areEqual('Approved Partial Refund', updatedCase.Refund_Status__c);
        Assert.areEqual(50.00, updatedCase.Refund_Amount__c);
        Assert.areEqual('Partial', updatedCase.Requested_Refund_Type__c);
    }
}
