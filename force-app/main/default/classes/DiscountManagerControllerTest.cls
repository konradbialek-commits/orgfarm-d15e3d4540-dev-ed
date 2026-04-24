@IsTest
private class DiscountManagerControllerTest {

    @TestSetup
    static void setupTestData() {
        Discount_Setting__c setting = new Discount_Setting__c(
            Name = 'Global',
            Strategy__c = 'Cumulative',
            Max_Discount_Percent__c = 0.0
        );
        insert setting;

        Discount__c d1 = new Discount__c(
            Name = '10 Percent Off',
            Active__c = true,
            Discount_Category__c = 'One Time Only',
            Discount_Type__c = 'Percent',
            Value__c = 10,
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addDays(10)
        );
        
        Discount__c d2 = new Discount__c(
            Name = '15 Fixed Off',
            Active__c = true,
            Discount_Category__c = 'Recurring',
            Discount_Type__c = 'Fixed Amount',
            Value__c = 15,
            Recurrence__c = 'None',
            Start_Date__c = Date.today().addDays(-1),
            End_Date__c = Date.today().addDays(10)
        );

        insert new List<Discount__c>{d1, d2};
    }

    @IsTest
    static void testSettings() {
        Test.startTest();
        Discount_Setting__c setting = DiscountManagerController.getGlobalSettings();
        Assert.isNotNull(setting);
        Assert.areEqual('Cumulative', setting.Strategy__c);

        setting.Strategy__c = 'Lowest';
        DiscountManagerController.saveGlobalSettings(setting);
        Test.stopTest();

        Discount_Setting__c updatedSetting = [SELECT Strategy__c FROM Discount_Setting__c LIMIT 1];
        Assert.areEqual('Lowest', updatedSetting.Strategy__c);
    }

    @IsTest
    static void testSettingsGeneration() {
        delete [SELECT Id FROM Discount_Setting__c];
        
        Test.startTest();
        Discount_Setting__c setting = DiscountManagerController.getGlobalSettings();
        Test.stopTest();
        
        Assert.isNotNull(setting);
        Assert.areEqual('Cumulative', setting.Strategy__c);
        Assert.areEqual(0.0, setting.Max_Discount_Percent__c);
    }

    @IsTest
    static void testDiscountDML() {
        Test.startTest();
        List<Discount__c> discounts = DiscountManagerController.getDiscounts();
        Assert.areEqual(2, discounts.size());

        List<Id> dIds = new List<Id>{discounts[0].Id};
        DiscountManagerController.toggleDiscounts(dIds, false);
        
        Discount__c newDiscount = new Discount__c(
            Name = 'New Test',
            Active__c = true,
            Discount_Category__c = 'One Time Only',
            Discount_Type__c = 'Percent',
            Value__c = 5
        );
        DiscountManagerController.upsertDiscount(newDiscount);
        Test.stopTest();

        Discount__c toggled = [SELECT Active__c FROM Discount__c WHERE Id = :dIds[0]];
        Assert.isFalse(toggled.Active__c);
        
        Integer count = [SELECT COUNT() FROM Discount__c];
        Assert.areEqual(3, count);
    }

    @IsTest
    static void testCalculateCumulative() {
        Test.startTest();
        Map<String, Object> result = DiscountManagerController.calculateOrderDiscounts(100.0);
        Test.stopTest();

        Assert.areEqual(25.0, (Decimal)result.get('discountAmount'));
        Assert.areEqual(75.0, (Decimal)result.get('finalTotal'));
    }

    @IsTest
    static void testCalculateCapped() {
        Discount_Setting__c setting = [SELECT Id FROM Discount_Setting__c LIMIT 1];
        setting.Max_Discount_Percent__c = 80.0;
        update setting;

        Test.startTest();
        Map<String, Object> result = DiscountManagerController.calculateOrderDiscounts(100.0);
        Test.stopTest();

        Assert.areEqual(20.0, (Decimal)result.get('discountAmount'));
        Assert.areEqual(80.0, (Decimal)result.get('finalTotal'));
        Assert.isTrue(((String)result.get('appliedDiscounts')).contains('Floor'));
    }
}