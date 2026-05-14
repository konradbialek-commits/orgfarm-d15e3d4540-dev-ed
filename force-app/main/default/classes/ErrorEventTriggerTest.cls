@IsTest
private class ErrorEventTriggerTest {

    @IsTest
    static void testErrorLogCreation() {
        Error_Log__c mockLog = TestDataFactory.createErrorLog(
            'ERROR',
            Util.TEST.ERROR_LOG.DEFAULT_CLASS_NAME,
            Util.TEST.ERROR_LOG.DEFAULT_METHOD_NAME,
            Util.TEST.ERROR_LOG.DEFAULT_ERROR_MESSAGE,
            Util.TEST.ERROR_LOG.DEFAULT_STACK_TRACE
        );
        Error_Event__e testEvent = TestDataFactory.createDefaultErrorEvent(mockLog);

        Test.startTest();
        Database.SaveResult result = EventBus.publish(testEvent);
        Test.stopTest();

        Assert.isTrue(result.isSuccess());
        List<Error_Log__c> logs = [
            SELECT Log_Level__c, Class_Name__c, Method_Name__c, Error_Message__c, Stack_Trace__c 
            FROM Error_Log__c
        ];

        Assert.areEqual(1, logs.size());
        Assert.areEqual('ERROR', logs[0].Log_Level__c);
        Assert.areEqual(Util.TEST.ERROR_LOG.DEFAULT_CLASS_NAME, logs[0].Class_Name__c);
        Assert.areEqual(Util.TEST.ERROR_LOG.DEFAULT_METHOD_NAME, logs[0].Method_Name__c);
        Assert.areEqual(Util.TEST.ERROR_LOG.DEFAULT_ERROR_MESSAGE, logs[0].Error_Message__c);
        Assert.areEqual(Util.TEST.ERROR_LOG.DEFAULT_STACK_TRACE, logs[0].Stack_Trace__c);
    }

    @IsTest
    static void testWarningLogCreation() {
        Error_Log__c mockLog = TestDataFactory.createErrorLog(
            'WARNING',
            Util.TEST.ERROR_LOG.DEFAULT_CLASS_NAME,
            Util.TEST.ERROR_LOG.DEFAULT_METHOD_NAME,
            'Warning occurred',
            null
        );
        Error_Event__e testEvent = TestDataFactory.createDefaultErrorEvent(mockLog);

        Test.startTest();
        Database.SaveResult result = EventBus.publish(testEvent);
        Test.stopTest();

        Assert.isTrue(result.isSuccess());
        List<Error_Log__c> logs = [
            SELECT Log_Level__c, Error_Message__c
            FROM Error_Log__c
        ];

        Assert.areEqual(1, logs.size());
        Assert.areEqual('WARNING', logs[0].Log_Level__c);
        Assert.areEqual('Warning occurred', logs[0].Error_Message__c);
    }

    @IsTest
    static void testInfoLogCreation() {
        Error_Log__c mockLog = TestDataFactory.createErrorLog(
            'INFO',
            Util.TEST.ERROR_LOG.DEFAULT_CLASS_NAME,
            Util.TEST.ERROR_LOG.DEFAULT_METHOD_NAME,
            'Info message',
            null
        );
        Error_Event__e testEvent = TestDataFactory.createDefaultErrorEvent(mockLog);

        Test.startTest();
        Database.SaveResult result = EventBus.publish(testEvent);
        Test.stopTest();

        Assert.isTrue(result.isSuccess());
        List<Error_Log__c> logs = [
            SELECT Log_Level__c, Error_Message__c
            FROM Error_Log__c
        ];

        Assert.areEqual(1, logs.size());
        Assert.areEqual('INFO', logs[0].Log_Level__c);
        Assert.areEqual('Info message', logs[0].Error_Message__c);
    }
}