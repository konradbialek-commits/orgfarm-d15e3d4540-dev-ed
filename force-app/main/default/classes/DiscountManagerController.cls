public with sharing class DiscountManagerController {

    @AuraEnabled
    public static Discount_Setting__c getGlobalSettings() {
        List<Discount_Setting__c> settings = [SELECT Id, Strategy__c, Max_Discount_Percent__c FROM Discount_Setting__c LIMIT 1];
        if (settings.isEmpty()) {
            Discount_Setting__c newSetting = new Discount_Setting__c(Name = 'Global', Strategy__c = 'Cumulative', Max_Discount_Percent__c = 0.0);
            insert newSetting;
            return newSetting;
        }
        return settings[0];
    }

    @AuraEnabled
    public static void saveGlobalSettings(Discount_Setting__c setting) {
        update setting;
    }

    @AuraEnabled
    public static List<Discount__c> getDiscounts() {
        return [SELECT Id, Name, Active__c, Discount_Category__c, Discount_Type__c, Value__c, Recurrence__c, Custom_Recurrence_Date__c, Minimum_Order_Value__c, Start_Date__c, End_Date__c FROM Discount__c ORDER BY CreatedDate DESC];
    }

    @AuraEnabled
    public static void toggleDiscounts(List<Id> discountIds, Boolean isActive) {
        List<Discount__c> toUpdate = new List<Discount__c>();
        for (Id dId : discountIds) {
            toUpdate.add(new Discount__c(Id = dId, Active__c = isActive));
        }
        update toUpdate;
    }

    @AuraEnabled
    public static void deleteDiscounts(List<Id> discountIds) {
        delete [SELECT Id FROM Discount__c WHERE Id IN :discountIds];
    }

    @AuraEnabled
    public static void upsertDiscount(Discount__c discountRecord) {
        if (discountRecord.Discount_Type__c == 'Percent' && discountRecord.Value__c > 100) {
            throw new AuraHandledException('Percentage discounts cannot exceed 100%.');
        }
        
        if (discountRecord.Recurrence__c == 'Yearly Custom Date' && discountRecord.Custom_Recurrence_Date__c == null) {
            throw new AuraHandledException('Please provide a target date for the yearly recurrence.');
        }
        
        upsert discountRecord;
    }

    @AuraEnabled
    public static Map<String, Object> calculateOrderDiscounts(Decimal subtotal, Integer totalQuantity) {
        return DiscountService.calculateOrderDiscounts(subtotal, totalQuantity);
    }
}