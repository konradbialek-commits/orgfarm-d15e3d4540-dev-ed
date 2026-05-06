public without sharing class ErrorLogger {

    public static void logException(Exception except, String className, String methodName) {

        Error_Event__e newEvent = new Error_Event__e(
            Class_Name__c = className,
            Method_Name__c = methodName,
            Error_Message__c = except.getMessage(),
            Stack_Trace__c = except.getStackTraceString()
        );

        Database.SaveResult saveResult = EventBus.publish(newEvent);

        if (!saveResult.isSuccess()) {
            for (Database.Error error : saveResult.getErrors()) {
                System.debug(error.getStatusCode() + ' - ' + error.getMessage());
            }
        }
    }
}