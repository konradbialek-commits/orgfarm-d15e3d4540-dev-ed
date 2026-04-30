@isTest
private class DiscountServiceTest {
    
    @testSetup
    static void setupData() {
        Discount_Setting__c setting = new Discount_Setting__c(
            Name = 'Global',
            Strategy__c = 'Cumulative',
            Max_Discount_Percent__c = 20.0
        );
        insert setting;

        List<Discount__c> discounts = new List<Discount__c>();
        
        discounts.add(new Discount__c(
            Name = '10 Percent Off',
            Active__c = true,
            Discount_Category__c = 'One Time Only',
            Target_Type__c = 'All Products',
            Discount_Type__c = 'Percent',
            Value__c = 10.0
        ));

        discounts.add(new Discount__c(
            Name = '15 Fixed Off',
            Active__c = true,
            Discount_Category__c = 'Conditional',
            Condition_Type__c = 'Minimum Order Value',
            Minimum_Order_Value__c = 50.0,
            Target_Type__c = 'All Products',
            Discount_Type__c = 'Fixed Amount',
            Value__c = 15.0
        ));

        insert discounts;
    }

    static String getCartPayload() {
        return '[{"pricebookEntryId":"01u000000000000000","productId":"01t000000000000000","family":"Fiction","unitPrice":100.0,"quantity":1}]';
    }

    @isTest
    static void testCalculateOrderDiscountsCumulative() {
        Map<String, Object> result = DiscountService.calculateOrderDiscounts(getCartPayload());
        
        System.assertEquals(100.0, result.get('originalTotal'));
        System.assertEquals(25.0, result.get('discountAmount'));
        System.assertEquals(75.0, result.get('finalTotal'));
    }

    @isTest
    static void testHighestStrategy() {
        Discount_Setting__c setting = [SELECT Id FROM Discount_Setting__c LIMIT 1];
        setting.Strategy__c = 'Highest';
        update setting;

        Map<String, Object> result = DiscountService.calculateOrderDiscounts(getCartPayload());
        
        System.assertEquals(15.0, result.get('discountAmount'));
        System.assertEquals(85.0, result.get('finalTotal'));
    }

    @isTest
    static void testLowestStrategy() {
        Discount_Setting__c setting = [SELECT Id FROM Discount_Setting__c LIMIT 1];
        setting.Strategy__c = 'Lowest';
        update setting;

        Map<String, Object> result = DiscountService.calculateOrderDiscounts(getCartPayload());
        
        System.assertEquals(10.0, result.get('discountAmount'));
        System.assertEquals(90.0, result.get('finalTotal'));
    }

    @isTest
    static void testMaxDiscountFloor() {
        Discount_Setting__c setting = [SELECT Id FROM Discount_Setting__c LIMIT 1];
        setting.Strategy__c = 'Cumulative';
        setting.Max_Discount_Percent__c = 80.0;
        update setting;

        Map<String, Object> result = DiscountService.calculateOrderDiscounts(getCartPayload());
        
        System.assertEquals(20.0, result.get('discountAmount')); 
        System.assertEquals(80.0, result.get('finalTotal'));
    }
}