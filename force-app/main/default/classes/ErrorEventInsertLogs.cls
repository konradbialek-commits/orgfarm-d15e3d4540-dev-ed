public class ErrorEventInsertLogs implements TriggerAction.AfterInsert {
    
    public void afterInsert(List<SObject> newList) {
        Map<Type, List<SObject>> recordsToInsertByType = new Map<Type, List<SObject>>();

        for (Error_Event__e event : (List<Error_Event__e>) newList) {
            if (String.isNotBlank(event.Payload__c) && String.isNotBlank(event.SObject_Type__c)) {
                try {
                    Type targetType = Type.forName(event.SObject_Type__c);
                    
                    if (targetType != null) {
                        SObject record = (SObject) JSON.deserialize(event.Payload__c, targetType);
                        
                        if (!recordsToInsertByType.containsKey(targetType)) {
                            recordsToInsertByType.put(targetType, new List<SObject>());
                        }
                        recordsToInsertByType.get(targetType).add(record);
                    }
                } catch (Exception e) {
                    System.debug(e.getMessage());
                }
            }
        }

        for (List<SObject> records : recordsToInsertByType.values()) {
            if (!records.isEmpty()) {
                insert records;
            }
        }
    }
}