public without sharing class ErrorLogger {

    public enum LogLevel { ERROR, WARNING, INFO }

    private static void publishLog(LogLevel level, String className, String methodName, String message, String stackTrace, Id userId) {
        Error_Event__e newEvent = new Error_Event__e(
            Log_Level__c = level.name(),
            Class_Name__c = className,
            Method_Name__c = methodName,
            Error_Message__c = message,
            Stack_Trace__c = stackTrace,
            User_Id__c = userId
        );

        Database.SaveResult saveResult = EventBus.publish(newEvent);

        if (!saveResult.isSuccess()) {
            for (Database.Error error : saveResult.getErrors()) {
                System.debug(error.getStatusCode() + ' - ' + error.getMessage());
            }
        }
    }

    public static void logException(Exception except, String className, String methodName, Id userId) {
        publishLog(LogLevel.ERROR, className, methodName, except.getMessage(), except.getStackTraceString(), userId);
    }

    public static void logException(Exception except, String className, String methodName) {
        logException(except, className, methodName, UserInfo.getUserId());
    }

    public static void logException(Exception except) {
        logException(except, 'Anonymous', 'Anonymous', UserInfo.getUserId());
    }

    public static void logWarning(String message, String className, String methodName) {
        publishLog(LogLevel.WARNING, className, methodName, message, null, UserInfo.getUserId());
    }

    public static void logWarning(String message) {
        logWarning(message, 'Anonymous', 'Anonymous');
    }

    public static void logInfo(String message, String className, String methodName) {
        publishLog(LogLevel.INFO, className, methodName, message, null, UserInfo.getUserId());
    }

    public static void logInfo(String message) {
        logInfo(message, 'Anonymous', 'Anonymous');
    }
}