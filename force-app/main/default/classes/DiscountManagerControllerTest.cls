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
            Target_Type__c = 'Specific Products',
            Discount_Type__c = 'Percent', 
            Value__c = 10
        );
        DiscountManagerController.upsertDiscount(d, new List<Id>{'01t000000000000000'});
        
        List<Discount__c> discounts = DiscountManagerController.getDiscounts();
        System.assertEquals(1, discounts.size());

        DiscountManagerController.toggleDiscounts(new List<Id>{d.Id}, true);
        System.assertEquals(true, [SELECT Active__c FROM Discount__c WHERE Id = :d.Id].Active__c);

        String cartPayload = '[{"pricebookEntryId":"01u000000000000000","productId":"01t000000000000000","family":"Fiction","unitPrice":100.0,"quantity":1}]';
        Map<String, Object> calcResult = DiscountManagerController.calculateOrderDiscounts(cartPayload);
        System.assertNotEquals(null, calcResult);

        DiscountManagerController.deleteDiscounts(new List<Id>{d.Id});
        System.assertEquals(0, [SELECT Count() FROM Discount__c]);
    }
    
    @isTest
    static void testUpsertExceptions() {
        Discount__c dTooHigh = new Discount__c(Discount_Type__c = 'Percent', Value__c = 110);
        try {
            DiscountManagerController.upsertDiscount(dTooHigh, null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }

        Discount__c dMissingDate = new Discount__c(Recurrence__c = 'Yearly Custom Date');
        try {
            DiscountManagerController.upsertDiscount(dMissingDate, null);
            System.assert(false);
        } catch (Exception e) {
            System.assert(true);
        }
    }

    @isTest
    static void testDataRetrieval() {
        System.assertNotEquals(null, DiscountManagerController.getAvailableFamilies());
        System.assertNotEquals(null, DiscountManagerController.getAvailableProducts());
    }
}