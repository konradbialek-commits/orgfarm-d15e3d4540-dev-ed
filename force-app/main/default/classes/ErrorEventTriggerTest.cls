@IsTest
private class ErrorEventTriggerTest {

    @IsTest
    static void testErrorLogCreation() {
        Error_Log__c mockLog = new Error_Log__c(
            Log_Level__c = 'ERROR',
            Class_Name__c = 'TestClass',
            Method_Name__c = 'TestMethod',
            Error_Message__c = 'Test exception message',
            Stack_Trace__c = 'Line 1\nLine 2'
        );
        Error_Event__e testEvent = new Error_Event__e(
            SObject_Type__c = 'Error_Log__c',
            Payload__c = JSON.serialize(mockLog)
        );

        Test.startTest();
        Database.SaveResult result = EventBus.publish(testEvent);
        Test.stopTest();

        System.assert(result.isSuccess(), 'The platform event should publish successfully');
        List<Error_Log__c> logs = [
            SELECT Class_Name__c, Method_Name__c, Error_Message__c, Stack_Trace__c 
            FROM Error_Log__c
        ];

        System.assertEquals(1, logs.size(), 'One error log should be inserted');
        System.assertEquals('TestClass', logs[0].Class_Name__c, 'Class name should match');
        System.assertEquals('TestMethod', logs[0].Method_Name__c, 'Method name should match');
        System.assertEquals('Test exception message', logs[0].Error_Message__c, 'Error message should match');
    }
}