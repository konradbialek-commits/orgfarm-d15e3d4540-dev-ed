public with sharing class DiscountManagerController {

    @AuraEnabled
    public static Discount_Setting__c getGlobalSettings() {
        try {
            List<Discount_Setting__c> settings = [SELECT Id, Strategy__c, Minimum_Price_Floor_Percent__c FROM Discount_Setting__c LIMIT 1];
            if (settings.isEmpty()) {
                Discount_Setting__c newSetting = new Discount_Setting__c(
                    Name = Util.Settings.DEFAULT_NAME, 
                    Strategy__c = Util.Settings.STRATEGY_CUMULATIVE, 
                    Minimum_Price_Floor_Percent__c = 0.0
                );
                insert newSetting;
                return newSetting;
            }
        } catch (Exception exception) {
            Error_Event__e newEvent = new Error_Event__e(
                Class_Name__c = 'DiscountManagerController', 
                Method_Name__c = 'getGlobalSettings',
                Error_Message__c = exception.getMessage(),
                Stack_Trace__c = exception.getStackTraceString()
            );
            Database.SaveResult saveResult = EventBus.publish(newEvent);

            if (!saveResult.isSuccess()) {
                for (Database.Error error : saveResult.getErrors()) {
                    System.debug('Error publishing event: ' + error.getStatusCode() + ' - ' + error.getMessage());
                }
            }
        }
        return settings[0];
    }

    @AuraEnabled
    public static void saveGlobalSettings(Discount_Setting__c setting) {
        update setting;
    }

    @AuraEnabled
    public static List<Discount__c> getDiscounts() {
        return [
            SELECT Id, Name, Active__c, Discount_Category__c, Condition_Type__c, Discount_Type__c, 
                   Value__c, Recurrence__c, Custom_Recurrence_Date__c, Minimum_Order_Value__c, 
                   Start_Date__c, End_Date__c, Target_Type__c, Eligible_Families__c 
            FROM Discount__c 
            ORDER BY CreatedDate DESC
        ];
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
    public static void upsertDiscount(Discount__c discountRecord, List<Id> selectedProductIds) {
        if (discountRecord.Discount_Type__c == Util.Discount.TYPE_PERCENT && discountRecord.Value__c > 100) {
            throw new AuraHandledException(System.Label.DM_Err_PctExceed);
        }
        
        if (discountRecord.Recurrence__c == Util.Discount.REC_YEARLY_CUSTOM && discountRecord.Custom_Recurrence_Date__c == null) {
            throw new AuraHandledException(System.Label.DM_Err_ReqTargetDate);
        }
        
        upsert discountRecord;

        delete [SELECT Id FROM Discount_Product__c WHERE Discount__c = :discountRecord.Id];

        if (discountRecord.Target_Type__c == Util.Discount.TARGET_PRODUCTS && selectedProductIds != null && !selectedProductIds.isEmpty()) {
            List<Discount_Product__c> junctionRecords = new List<Discount_Product__c>();
            for (Id pId : selectedProductIds) {
                junctionRecords.add(new Discount_Product__c(
                    Discount__c = discountRecord.Id,
                    Product__c = pId
                ));
            }
            insert junctionRecords;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getAvailableFamilies() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
        for(Schema.PicklistEntry f : fieldResult.getPicklistValues()) {
            options.add(new Map<String, String>{
                'label' => f.getLabel(),
                'value' => f.getValue()
            });
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<Product2> getAvailableProducts() {
        return [SELECT Id, Name, Family FROM Product2 WHERE IsActive = true ORDER BY Name ASC];
    }

    @AuraEnabled
    public static Map<String, Object> calculateOrderDiscounts(String cartPayload) {
        return DiscountService.calculateOrderDiscounts(cartPayload);
    }
    
    @AuraEnabled
    public static List<Id> getDiscountProducts(Id discountId) {
        List<Id> productIds = new List<Id>();
        for (Discount_Product__c dp : [SELECT Product__c FROM Discount_Product__c WHERE Discount__c = :discountId]) {
            productIds.add(dp.Product__c);
        }
        return productIds;
    }
}