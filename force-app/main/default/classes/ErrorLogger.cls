public without sharing class ErrorLogger {
    public enum LogLevel {
        ERROR,
        WARNING,
        INFO
    }

    public static void log(SObject recordToLog) {
        Error_Event__e newEvent = new Error_Event__e(
            SObject_Type__c = String.valueOf(recordToLog.getSObjectType()),
            Payload__c = JSON.serialize(recordToLog)
        );

        Database.SaveResult saveResult = EventBus.publish(newEvent);

        if (!saveResult.isSuccess()) {
            for (Database.Error error : saveResult.getErrors()) {
                System.debug(error.getStatusCode() + ' - ' + error.getMessage());
            }
        }
    }

    private static void prepareAndLog(LogLevel level, String className, String methodName, String message, String stackTrace, Id userId) {
        Error_Log__c logRecord = new Error_Log__c(
            Log_Level__c = level.name(),
            Class_Name__c = className,
            Method_Name__c = methodName,
            Error_Message__c = message,
            Stack_Trace__c = stackTrace,
            User__c = userId
        );

        log(logRecord);
    }

    @AuraEnabled
    public static void logClientError(String errorMessage, String stackTrace, String componentName, String methodName) {
        try {
            logWarning(
                'CLIENT ERROR: ' + errorMessage + (String.isNotBlank(stackTrace) ? '\nStack: ' + stackTrace : ''),
                componentName,
                methodName
            );
        } catch (Exception e) {
            System.debug('Failed to log client error: ' + e.getMessage());
        }
    }

    public static void logException(Exception except, String className, String methodName, Id userId) {
        prepareAndLog(LogLevel.ERROR, className, methodName, except.getMessage(), except.getStackTraceString(), userId);
    }

    public static void logException(Exception except, String className, String methodName) {
        logException(except, className, methodName, UserInfo.getUserId());
    }

    public static void logException(Exception except) {
        logException(except, 'Anonymous', 'Anonymous', UserInfo.getUserId());
    }

    public static void logWarning(String message, String className, String methodName) {
        prepareAndLog(LogLevel.WARNING, className, methodName, message, null, UserInfo.getUserId());
    }

    public static void logWarning(String message) {
        logWarning(message, 'Anonymous', 'Anonymous');
    }

    public static void logInfo(String message, String className, String methodName) {
        prepareAndLog(LogLevel.INFO, className, methodName, message, null, UserInfo.getUserId());
    }

    public static void logInfo(String message) {
        logInfo(message, 'Anonymous', 'Anonymous');
    }
}
