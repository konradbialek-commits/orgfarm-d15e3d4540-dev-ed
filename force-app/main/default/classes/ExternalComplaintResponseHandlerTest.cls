@IsTest
private class ExternalComplaintResponseHandlerTest {
    @IsTest
    static void testInboundResponseUpdatesLineItems() {
        Account testAcc = TestDataFactory.createAccount('Test Account');
        insert testAcc;

        Order mockOrder = TestDataFactory.createOrder(testAcc.Id, 'Draft', Date.today(), null);
        insert mockOrder;

        RefundActionService.PendingComplaint pc = new RefundActionService.PendingComplaint();
        pc.correlationId = '123e4567-e89b-12d3-a456-426614174000';
        pc.reason = 'Mixed Request';

        RefundActionService.PendingLine pl1 = new RefundActionService.PendingLine();
        pl1.isExternal = true;
        pl1.externalProductId = 'EXT-001';
        pl1.refundAmount = 50.00;
        pl1.refundType = 'Partial';
        pl1.productName = 'Ext Prod 1';

        RefundActionService.PendingLine pl2 = new RefundActionService.PendingLine();
        pl2.isExternal = false;
        pl2.externalProductId = null;
        pl2.refundAmount = 10.00;
        pl2.refundType = 'Full';
        pl2.productName = 'Local Prod';

        pc.lines = new List<RefundActionService.PendingLine>{ pl1, pl2 };

        mockOrder.Pending_Complaint_JSON__c = JSON.serialize(pc);
        update mockOrder;

        List<Map<String, Object>> responseLines = new List<Map<String, Object>>{
            new Map<String, Object>{
                'productId' => 'EXT-001',
                'status' => 'Approved Partial Refund',
                'refundAmount' => 45.00,
                'refundType' => 'Partial'
            }
        };

        External_Complaint_Response__e responseEvent = new External_Complaint_Response__e(
            Case_Id__c = '123e4567-e89b-12d3-a456-426614174000',
            Status__c = 'Approved Partial Refund',
            Line_Items_JSON__c = JSON.serialize(responseLines)
        );

        Test.startTest();
        EventBus.publish(responseEvent);
        Test.stopTest();

        List<Case> cases = [SELECT Id, External_Case_Id__c FROM Case];
        Assert.areEqual(1, cases.size());

        List<Case_Order_Product__c> cops = [SELECT External_Product_Id__c, Refund_Status__c, Refund_Amount__c FROM Case_Order_Product__c];
        Assert.areEqual(2, cops.size());
    }
}
