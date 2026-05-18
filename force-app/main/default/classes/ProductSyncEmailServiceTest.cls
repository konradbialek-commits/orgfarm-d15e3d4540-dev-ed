@IsTest
private class ProductSyncEmailServiceTest {
    @TestSetup
    static void setupData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            EmailTemplate mockTemplate = new EmailTemplate(
                IsActive = true,
                Name = 'Product Sync Failure Template',
                DeveloperName = 'Product_Sync_Failure_Template',
                TemplateType = 'custom',
                FolderId = UserInfo.getUserId(),
                Subject = 'ACTION REQUIRED: Product Synchronization Failures',
                Body = 'Hello [USER_NAME],\n\n[FAILED_PRODUCTS_LIST]',
                HtmlValue = '<html><body>Hello [USER_NAME],<br/>[FAILED_PRODUCTS_LIST]</body></html>'
            );
            insert mockTemplate;
        }

        Product2 testProduct = TestDataFactory.createDefaultProduct();
        insert testProduct;

        Product_Sync_Queue__c failedItem = TestDataFactory.createDefaultQueueItem(testProduct.Id);
        failedItem.Status__c = Util.PRODUCT_SYNC_QUEUE.STATUS.FAILED;
        failedItem.Attempt_Count__c = 3;
        failedItem.Error_Message__c = 'Simulated timeout error';
        insert failedItem;
    }

    @IsTest
    static void testSendFailureNotificationsSuccess() {
        List<Product_Sync_Queue__c> failedItems = [
            SELECT Id, Product__c, Operation__c, Error_Message__c
            FROM Product_Sync_Queue__c
        ];

        Map<Id, Product2> productsMap = new Map<Id, Product2>(
            [
                SELECT Id, Name, ProductCode
                FROM Product2
            ]
        );

        Test.startTest();
        ProductSyncEmailService.sendFailureNotifications(failedItems, productsMap);
        Test.stopTest();

        List<Error_Log__c> logs = [SELECT Error_Message__c FROM Error_Log__c ORDER BY CreatedDate DESC];

        if (Limits.getEmailInvocations() == 0) {
            Assert.isFalse(logs.isEmpty());
            Assert.isTrue(logs[0].Error_Message__c.containsIgnoreCase('Email'), 'Unexpected Error: ' + logs[0].Error_Message__c);
        } else {
            Assert.areEqual(1, Limits.getEmailInvocations());
        }
    }

    @IsTest
    static void testSendFailureNotificationsException() {
        List<Product_Sync_Queue__c> failedItems = [
            SELECT Id, Product__c, Operation__c, Error_Message__c
            FROM Product_Sync_Queue__c
        ];

        Test.startTest();
        ProductSyncEmailService.sendFailureNotifications(failedItems, null);
        Test.stopTest();

        Assert.areEqual(0, Limits.getEmailInvocations());

        List<Error_Log__c> logs = [
            SELECT Id, Class_Name__c, Method_Name__c, Error_Message__c
            FROM Error_Log__c
            WHERE Class_Name__c = 'ProductSyncEmailService'
        ];

        Assert.isFalse(logs.isEmpty());
        Assert.areEqual('ProductSyncEmailService', logs[0].Class_Name__c);
        Assert.areEqual('sendFailureNotifications', logs[0].Method_Name__c);
    }
}
