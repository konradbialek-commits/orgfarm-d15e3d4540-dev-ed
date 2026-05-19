@IsTest
private class ExternalComplaintHandlerTest {
    @TestSetup
    static void setupData() {
        Account testAcc = new Account(Name = 'Test Account');
        insert testAcc;

        Order testOrder = new Order(AccountId = testAcc.Id, Status = 'Draft', EffectiveDate = Date.today());
        insert testOrder;
    }

    @IsTest
    static void testInboundEventWithValidLocalOrder() {
        Order localOrder = [SELECT Id FROM Order LIMIT 1];

        External_Complaint__e ev = new External_Complaint__e(
            Order_id__c = String.valueOf(localOrder.Id),
            Case_Id__c = '500x00000000000AAA',
            Reason__c = 'Full - Product was damaged',
            Product_Ids__c = '01tx00000000000AAA'
        );

        Test.startTest();
        EventBus.publish(ev);
        Test.stopTest();

        Case insertedCase = [
            SELECT Order__c, Requested_Refund_Type__c, External_Case_Id__c, Description
            FROM Case
            WHERE External_Case_Id__c = '500x00000000000AAA'
            LIMIT 1
        ];

        Assert.areEqual(localOrder.Id, insertedCase.Order__c);
        Assert.areEqual('Full', insertedCase.Requested_Refund_Type__c);
        Assert.areEqual('500x00000000000AAA', insertedCase.External_Case_Id__c);
        Assert.isTrue(insertedCase.Description.contains('Product was damaged'));
    }

    @IsTest
    static void testInboundEventWithExternalOrder() {
        External_Complaint__e ev = new External_Complaint__e(
            Order_id__c = '801x00000000000ZZZ',
            Case_Id__c = '500x00000000000BBB',
            Reason__c = 'Partial - Missing parts',
            Product_Ids__c = '01tx00000000000BBB'
        );

        Test.startTest();
        EventBus.publish(ev);
        Test.stopTest();

        Case insertedCase = [
            SELECT Order__c, Requested_Refund_Type__c, External_Case_Id__c, Description
            FROM Case
            WHERE External_Case_Id__c = '500x00000000000BBB'
            LIMIT 1
        ];

        Assert.isNull(insertedCase.Order__c);
        Assert.areEqual('Partial', insertedCase.Requested_Refund_Type__c);
        Assert.isTrue(insertedCase.Description.contains('External Order ID: 801x00000000000ZZZ'));
    }

    @IsTest
    static void testInboundEventWithMalformedOrderId() {
        External_Complaint__e ev = new External_Complaint__e(
            Order_id__c = 'INVALID_ID_FORMAT',
            Case_Id__c = '500x00000000000CCC',
            Reason__c = 'Full - Wrong item',
            Product_Ids__c = '01tx00000000000CCC'
        );

        Test.startTest();
        EventBus.publish(ev);
        Test.stopTest();

        Case insertedCase = [
            SELECT Order__c, External_Case_Id__c
            FROM Case
            WHERE External_Case_Id__c = '500x00000000000CCC'
            LIMIT 1
        ];

        Assert.isNull(insertedCase.Order__c);

        List<Error_Log__c> logs = [
            SELECT Error_Message__c
            FROM Error_Log__c
            WHERE Class_Name__c = 'ExternalComplaintHandler'
        ];

        Assert.isFalse(logs.isEmpty());
        Assert.isTrue(logs[0].Error_Message__c.contains('Invalid Order ID format'));
    }
}
