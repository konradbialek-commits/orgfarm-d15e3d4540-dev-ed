public with sharing class DiscountManagerController {

    @AuraEnabled
    public static Discount_Setting__c getGlobalSettings() {
        List<Discount_Setting__c> settings = [SELECT Id, Strategy__c, Max_Discount_Percent__c FROM Discount_Setting__c LIMIT 1];
        if (settings.isEmpty()) {
            Discount_Setting__c newSetting = new Discount_Setting__c(Name = 'Global', Strategy__c = 'Cumulative', Max_Discount_Percent__c = 100.0);
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
        return [SELECT Id, Name, Active__c, Discount_Type__c, Value__c, Recurrence__c, Start_Date__c, End_Date__c FROM Discount__c ORDER BY CreatedDate DESC];
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
    public static void upsertDiscount(Discount__c discountRecord) {
        upsert discountRecord;
    }

    @AuraEnabled
    public static Map<String, Object> calculateOrderDiscounts(Decimal subtotal) {
        Discount_Setting__c settings = getGlobalSettings();
        Date today = Date.today();
        
        List<Discount__c> activeDiscounts = [
            SELECT Name, Discount_Type__c, Value__c, Recurrence__c 
            FROM Discount__c 
            WHERE Active__c = true 
            AND (Start_Date__c <= :today OR Start_Date__c = null)
            AND (End_Date__c >= :today OR End_Date__c = null)
        ];

        List<Discount__c> applicableDiscounts = new List<Discount__c>();
        for (Discount__c d : activeDiscounts) {
            if (d.Recurrence__c == 'First Day of Month' && today.day() != 1) continue;
            if (d.Recurrence__c == 'Every Monday' && DateTime.newInstance(today.year(), today.month(), today.day()).format('EEEE') != 'Monday') continue;
            applicableDiscounts.add(d);
        }

        Decimal totalDiscountAmount = 0;
        List<String> appliedNames = new List<String>();

        if (!applicableDiscounts.isEmpty()) {
            if (settings.Strategy__c == 'Cumulative') {
                for (Discount__c d : applicableDiscounts) {
                    appliedNames.add(d.Name);
                    if (d.Discount_Type__c == 'Percent') {
                        totalDiscountAmount += subtotal * (d.Value__c / 100);
                    } else {
                        totalDiscountAmount += d.Value__c;
                    }
                }
            } else if (settings.Strategy__c == 'Highest' || settings.Strategy__c == 'Lowest') {
                Discount__c selectedDiscount = applicableDiscounts[0];
                Decimal bestValue = 0;
                
                for (Discount__c d : applicableDiscounts) {
                    Decimal currentVal = d.Discount_Type__c == 'Percent' ? subtotal * (d.Value__c / 100) : d.Value__c;
                    Decimal selectedVal = selectedDiscount.Discount_Type__c == 'Percent' ? subtotal * (selectedDiscount.Value__c / 100) : selectedDiscount.Value__c;
                    
                    if (settings.Strategy__c == 'Highest' && currentVal > selectedVal) selectedDiscount = d;
                    if (settings.Strategy__c == 'Lowest' && currentVal < selectedVal) selectedDiscount = d;
                }
                
                appliedNames.add(selectedDiscount.Name);
                totalDiscountAmount = selectedDiscount.Discount_Type__c == 'Percent' ? subtotal * (selectedDiscount.Value__c / 100) : selectedDiscount.Value__c;
            }
        }

        Decimal maxDiscountAllowed = subtotal * (settings.Max_Discount_Percent__c / 100);
        if (totalDiscountAmount > maxDiscountAllowed) {
            totalDiscountAmount = maxDiscountAllowed;
            appliedNames.add('(Capped at Max ' + settings.Max_Discount_Percent__c + '%)');
        }

        Map<String, Object> result = new Map<String, Object>();
        result.put('originalTotal', subtotal);
        result.put('discountAmount', totalDiscountAmount);
        result.put('finalTotal', subtotal - totalDiscountAmount);
        result.put('appliedDiscounts', String.join(appliedNames, ', '));
        
        return result;
    }
}