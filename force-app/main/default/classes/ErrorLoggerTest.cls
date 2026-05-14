@IsTest
private class ErrorLoggerTest {

    @IsTest
    static void testLogExceptionDetailed() {
        Test.startTest();
        try {
            Integer causeMathException = 1 / 0;
        } catch (Exception e) {
            ErrorLogger.logException(e, Util.TEST.ERROR_LOG.DEFAULT_CLASS_NAME, Util.TEST.ERROR_LOG.DEFAULT_METHOD_NAME);
        }
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Log_Level__c, Class_Name__c, Method_Name__c, Error_Message__c 
            FROM Error_Log__c
        ];

        Assert.areEqual(1, logs.size());
        Assert.areEqual('ERROR', logs[0].Log_Level__c);
        Assert.areEqual(Util.TEST.ERROR_LOG.DEFAULT_CLASS_NAME, logs[0].Class_Name__c);
        Assert.areEqual(Util.TEST.ERROR_LOG.DEFAULT_METHOD_NAME, logs[0].Method_Name__c);
        Assert.isTrue(logs[0].Error_Message__c.contains('Divide by 0'));
    }

    @IsTest
    static void testLogExceptionAnonymous() {
        Test.startTest();
        try {
            Integer causeMathException = 1 / 0;
        } catch (Exception e) {
            ErrorLogger.logException(e);
        }
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Log_Level__c, Class_Name__c, Method_Name__c 
            FROM Error_Log__c
        ];

        Assert.areEqual(1, logs.size());
        Assert.areEqual('ERROR', logs[0].Log_Level__c);
        Assert.areEqual('Anonymous', logs[0].Class_Name__c);
        Assert.areEqual('Anonymous', logs[0].Method_Name__c);
    }

    @IsTest
    static void testLogWarningDetailed() {
        Test.startTest();
        ErrorLogger.logWarning('Test warning message', Util.TEST.ERROR_LOG.DEFAULT_CLASS_NAME, Util.TEST.ERROR_LOG.DEFAULT_METHOD_NAME);
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Log_Level__c, Class_Name__c, Method_Name__c, Error_Message__c 
            FROM Error_Log__c
        ];

        Assert.areEqual(1, logs.size());
        Assert.areEqual('WARNING', logs[0].Log_Level__c);
        Assert.areEqual(Util.TEST.ERROR_LOG.DEFAULT_CLASS_NAME, logs[0].Class_Name__c);
        Assert.areEqual(Util.TEST.ERROR_LOG.DEFAULT_METHOD_NAME, logs[0].Method_Name__c);
        Assert.areEqual('Test warning message', logs[0].Error_Message__c);
    }

    @IsTest
    static void testLogWarningAnonymous() {
        Test.startTest();
        ErrorLogger.logWarning('Test warning message');
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Log_Level__c, Class_Name__c, Method_Name__c, Error_Message__c 
            FROM Error_Log__c
        ];

        Assert.areEqual(1, logs.size());
        Assert.areEqual('WARNING', logs[0].Log_Level__c);
        Assert.areEqual('Anonymous', logs[0].Class_Name__c);
        Assert.areEqual('Anonymous', logs[0].Method_Name__c);
        Assert.areEqual('Test warning message', logs[0].Error_Message__c);
    }

    @IsTest
    static void testLogInfoDetailed() {
        Test.startTest();
        ErrorLogger.logInfo('Test info message', Util.TEST.ERROR_LOG.DEFAULT_CLASS_NAME, Util.TEST.ERROR_LOG.DEFAULT_METHOD_NAME);
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Log_Level__c, Class_Name__c, Method_Name__c, Error_Message__c 
            FROM Error_Log__c
        ];

        Assert.areEqual(1, logs.size());
        Assert.areEqual('INFO', logs[0].Log_Level__c);
        Assert.areEqual(Util.TEST.ERROR_LOG.DEFAULT_CLASS_NAME, logs[0].Class_Name__c);
        Assert.areEqual(Util.TEST.ERROR_LOG.DEFAULT_METHOD_NAME, logs[0].Method_Name__c);
        Assert.areEqual('Test info message', logs[0].Error_Message__c);
    }

    @IsTest
    static void testLogInfoAnonymous() {
        Test.startTest();
        ErrorLogger.logInfo('Test info message');
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Log_Level__c, Class_Name__c, Method_Name__c, Error_Message__c 
            FROM Error_Log__c
        ];

        Assert.areEqual(1, logs.size());
        Assert.areEqual('INFO', logs[0].Log_Level__c);
        Assert.areEqual('Anonymous', logs[0].Class_Name__c);
        Assert.areEqual('Anonymous', logs[0].Method_Name__c);
        Assert.areEqual('Test info message', logs[0].Error_Message__c);
    }
}