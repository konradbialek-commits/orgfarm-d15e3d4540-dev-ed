trigger ErrorEventTrigger on Error_Event__e (after insert) {
    List<Error_Log__c> logsToInsert = new List<Error_Log__c>();
    
    for (Error_Event__e event : Trigger.new) {
        logsToInsert.add(new Error_Log__c(
            Class_Name__c = event.Class_Name__c,
            Method_Name__c = event.Method_Name__c,
            Error_Message__c = event.Error_Message__c,
            Stack_Trace__c = event.Stack_Trace__c
        ));
    }
    
    if (!logsToInsert.isEmpty()) {
        insert logsToInsert;
    }
}