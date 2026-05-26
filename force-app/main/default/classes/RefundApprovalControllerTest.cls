@IsTest
private class RefundApprovalControllerTest {
    @TestSetup
    static void setupData() {
        Account testAcc = TestDataFactory.createAccount('Test Account');
        insert testAcc;

        Order testOrder = TestDataFactory.createOrder(testAcc.Id, 'Draft', Date.today(), null);
        insert testOrder;

        Case testCase = new Case(Subject = 'Refund Test', Order__c = testOrder.Id, Refund_Status__c = 'Pending');
        insert testCase;

        Case_Order_Product__c cop1 = new Case_Order_Product__c(
            Case__c = testCase.Id,
            Refund_Status__c = 'Pending',
            Refund_Amount__c = 100.00
        );
        Case_Order_Product__c cop2 = new Case_Order_Product__c(
            Case__c = testCase.Id,
            Refund_Status__c = 'Pending',
            Refund_Amount__c = 50.00
        );
        insert new List<Case_Order_Product__c>{ cop1, cop2 };

        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(testCase.Id);
        req.setSubmitterId(UserInfo.getUserId());
        Approval.process(req);
    }

    @IsTest
    static void testGetCaseProducts() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        List<Case_Order_Product__c> products = RefundApprovalController.getCaseProducts(testCase.Id);
        Test.stopTest();

        Assert.areEqual(2, products.size());
    }

    @IsTest
    static void testProcessBulkApproval() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];
        List<Case_Order_Product__c> products = [SELECT Id FROM Case_Order_Product__c WHERE Case__c = :testCase.Id];

        List<RefundApprovalService.LineItemUpdate> updates = new List<RefundApprovalService.LineItemUpdate>();

        RefundApprovalService.LineItemUpdate update1 = new RefundApprovalService.LineItemUpdate();
        update1.id = products[0].Id;
        update1.status = Util.COMPLAINT.STATUS.APPROVED_FULL;
        updates.add(update1);

        RefundApprovalService.LineItemUpdate update2 = new RefundApprovalService.LineItemUpdate();
        update2.id = products[1].Id;
        update2.status = Util.COMPLAINT.STATUS.APPROVED_PARTIAL;
        update2.approvedAmount = 25.00;
        updates.add(update2);

        Test.startTest();
        RefundApprovalController.processBulkApproval(testCase.Id, 'Looks good', JSON.serialize(updates));
        Test.stopTest();

        List<Case_Order_Product__c> updatedProducts = [
            SELECT Refund_Status__c, Refund_Amount__c
            FROM Case_Order_Product__c
            ORDER BY Refund_Amount__c DESC
        ];
        Assert.areEqual(Util.COMPLAINT.STATUS.APPROVED_FULL, updatedProducts[0].Refund_Status__c);
        Assert.areEqual(Util.COMPLAINT.STATUS.APPROVED_PARTIAL, updatedProducts[1].Refund_Status__c);
        Assert.areEqual(25.00, updatedProducts[1].Refund_Amount__c);

        List<ProcessInstance> instances = [SELECT Status FROM ProcessInstance WHERE TargetObjectId = :testCase.Id];
        Assert.areEqual('Approved', instances[0].Status);
    }

    @IsTest
    static void testRejectCase() {
        Case testCase = [SELECT Id FROM Case LIMIT 1];

        Test.startTest();
        RefundApprovalController.rejectCase(testCase.Id, 'Rejecting the whole thing');
        Test.stopTest();

        List<Case_Order_Product__c> updatedProducts = [SELECT Refund_Status__c FROM Case_Order_Product__c];
        for (Case_Order_Product__c cop : updatedProducts) {
            Assert.areEqual(Util.COMPLAINT.STATUS.REJECTED, cop.Refund_Status__c);
        }

        List<ProcessInstance> instances = [SELECT Status FROM ProcessInstance WHERE TargetObjectId = :testCase.Id];
        Assert.areEqual('Rejected', instances[0].Status);
    }
}
