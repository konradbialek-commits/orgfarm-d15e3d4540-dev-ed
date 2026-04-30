@isTest
private class DiscountManagerControllerTest {
    
    @isTest
    static void testControllerMethods() {
        Discount_Setting__c setting = DiscountManagerController.getGlobalSettings();
        System.assertNotEquals(null, setting);

        setting.Max_Discount_Percent__c = 5.0;
        DiscountManagerController.saveGlobalSettings(setting);
        Discount_Setting__c updatedSetting = DiscountManagerController.getGlobalSettings();
        System.assertEquals(5.0, updatedSetting.Max_Discount_Percent__c);

        Discount__c d = new Discount__c(
            Name = 'Test', 
            Active__c = false, 
            Discount_Type__c = 'Percent', 
            Value__c = 10
        );
        DiscountManagerController.upsertDiscount(d);
        
        List<Discount__c> discounts = DiscountManagerController.getDiscounts();
        System.assertEquals(1, discounts.size());

        DiscountManagerController.toggleDiscounts(new List<Id>{d.Id}, true);
        System.assertEquals(true, [SELECT Active__c FROM Discount__c WHERE Id = :d.Id].Active__c);

        Map<String, Object> calcResult = DiscountManagerController.calculateOrderDiscounts(100.0, 1);
        System.assertNotEquals(null, calcResult);

        DiscountManagerController.deleteDiscounts(new List<Id>{d.Id});
        System.assertEquals(0, [SELECT Count() FROM Discount__c]);
    }
    
    @isTest
    static void testUpsertExceptions() {
        Discount__c dTooHigh = new Discount__c(Discount_Type__c = 'Percent', Value__c = 110);
        try {
            DiscountManagerController.upsertDiscount(dTooHigh);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }

        Discount__c dMissingDate = new Discount__c(Recurrence__c = 'Yearly Custom Date');
        try {
            DiscountManagerController.upsertDiscount(dMissingDate);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
    }
}