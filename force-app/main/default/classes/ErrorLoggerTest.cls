@IsTest
private class ErrorLoggerTest {

    @IsTest
    static void testLogException() {
        Test.startTest();
        try {
            Integer causeMathException = 1 / 0;
        } catch (Exception e) {
            ErrorLogger.logException(e, 'MockController', 'mockMethod');
        }
        Test.stopTest();

        List<Error_Log__c> logs = [
            SELECT Class_Name__c, Method_Name__c, Error_Message__c 
            FROM Error_Log__c
        ];

        System.assertEquals(1, logs.size(), 'One error log should be created via the logger');
        System.assertEquals('MockController', logs[0].Class_Name__c, 'Class name should match');
        System.assertEquals('mockMethod', logs[0].Method_Name__c, 'Method name should match');
        System.assert(logs[0].Error_Message__c.contains('Divide by 0'), 'The native exception message should be captured');
    }
}