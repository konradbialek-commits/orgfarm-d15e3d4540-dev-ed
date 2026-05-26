@IsTest
private class ExternalComplaintResponseHandlerTest {
    @IsTest
    static void testInboundResponseLifecycle() {
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
        mockOrder.Refund_Status__c = 'Pending';
        update mockOrder;

        External_Complaint_Response__e creationEvent = new External_Complaint_Response__e(
            Case_Id__c = '123e4567-e89b-12d3-a456-426614174000',
            Status__c = Util.COMPLAINT.RESPONSE_STATUS.CREATED
        );

        Test.startTest();
        EventBus.publish(creationEvent);
        Test.getEventBus().deliver();

        List<Case> cases = [SELECT Id, External_Case_Id__c, Status FROM Case];
        Assert.areEqual(1, cases.size());

        List<Case_Order_Product__c> cops = [SELECT External_Product_Id__c, Refund_Status__c FROM Case_Order_Product__c];
        Assert.areEqual(2, cops.size());

        for (Case_Order_Product__c cop : cops) {
            Assert.areEqual(Util.COMPLAINT.STATUS.PENDING, cop.Refund_Status__c);
        }

        List<ExternalComplaintResponseHandler.RefundLineResponse> responseLines = new List<ExternalComplaintResponseHandler.RefundLineResponse>();
        ExternalComplaintResponseHandler.RefundLineResponse lineRes = new ExternalComplaintResponseHandler.RefundLineResponse();
        lineRes.productId = 'EXT-001';
        lineRes.status = Util.COMPLAINT.STATUS.APPROVED_PARTIAL;
        lineRes.refundAmount = 45.00;
        lineRes.refundType = 'Partial';
        responseLines.add(lineRes);

        External_Complaint_Response__e approvalEvent = new External_Complaint_Response__e(
            Case_Id__c = '123e4567-e89b-12d3-a456-426614174000',
            Status__c = Util.COMPLAINT.STATUS.APPROVED_PARTIAL,
            Line_Items_JSON__c = JSON.serialize(responseLines)
        );

        EventBus.publish(approvalEvent);
        Test.stopTest();

        List<Case_Order_Product__c> updatedCops = [
            SELECT External_Product_Id__c, Refund_Status__c, Refund_Amount__c
            FROM Case_Order_Product__c
            WHERE External_Product_Id__c = 'EXT-001'
        ];
        Assert.areEqual(1, updatedCops.size());
        Assert.areEqual(Util.COMPLAINT.STATUS.APPROVED_PARTIAL, updatedCops[0].Refund_Status__c);
        Assert.areEqual(45.00, updatedCops[0].Refund_Amount__c);
    }
}
