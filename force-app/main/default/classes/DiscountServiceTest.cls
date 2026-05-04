@isTest
private class DiscountServiceTest {
    
    @testSetup
    static void setupData() {
        Discount_Setting__c setting = new Discount_Setting__c(
            Name = Util.Settings.DEFAULT_NAME,
            Strategy__c = Util.Settings.STRATEGY_CUMULATIVE,
            Minimum_Price_Floor_Percent__c = 0.0
        );
        insert setting;
    }

    static String getCartPayload(Id pbeId, Id pId, Integer qty, Decimal price) {
        return '[{"pricebookEntryId":"' + pbeId + '","productId":"' + pId + '","family":"Test","unitPrice":' + price + ',"quantity":' + qty + '}]';
    }

    @isTest
    static void testTwoForOneEvaluatorMath() {
        Product2 prod = new Product2(Name = 'T-Shirt', IsActive = true);
        insert prod;
        
        Discount__c d = new Discount__c(
            Name = 'Buy 2 Get 1',
            Active__c = true,
            Discount_Category__c = Util.Discount.CAT_CONDITIONAL,
            Condition_Type__c = Util.Discount.COND_TWO_FOR_ONE,
            Target_Type__c = Util.Discount.TARGET_PRODUCTS,
            Discount_Type__c = Util.Discount.TYPE_PERCENT,
            Value__c = 100.0
        );
        insert d;
        
        insert new Discount_Product__c(Discount__c = d.Id, Product__c = prod.Id);

        String payload = getCartPayload('01u000000000001AAA', prod.Id, 3, 50.0);
        
        Map<String, Object> result = DiscountService.calculateOrderDiscounts(payload);
        
        System.assertEquals(150.0, result.get('originalTotal'));
        System.assertEquals(50.0, result.get('discountAmount'));
        System.assertEquals(100.0, result.get('finalTotal'));
    }

    @isTest
    static void testMinimumOrderEvaluator() {
        Product2 prod = new Product2(Name = 'Shoes', IsActive = true);
        insert prod;

        Discount__c d = new Discount__c(
            Name = 'Min 100 Get 20',
            Active__c = true,
            Discount_Category__c = Util.Discount.CAT_CONDITIONAL,
            Condition_Type__c = Util.Discount.COND_MIN_ORDER,
            Minimum_Order_Value__c = 100.0,
            Target_Type__c = Util.Discount.TARGET_ALL,
            Discount_Type__c = Util.Discount.TYPE_FIXED,
            Value__c = 20.0
        );
        insert d;

        String payload = getCartPayload('01u000000000002AAA', prod.Id, 1, 150.0);
        
        Map<String, Object> result = DiscountService.calculateOrderDiscounts(payload);
        
        System.assertEquals(150.0, result.get('originalTotal'));
        System.assertEquals(20.0, result.get('discountAmount'));
        System.assertEquals(130.0, result.get('finalTotal'));
    }

    @isTest
    static void testRecurringEvaluator() {
        Product2 prod = new Product2(Name = 'Socks', IsActive = true);
        insert prod;

        Discount__c d = new Discount__c(
            Name = 'Daily 10%',
            Active__c = true,
            Discount_Category__c = Util.Discount.CAT_RECURRING,
            Recurrence__c = 'Daily',
            Target_Type__c = Util.Discount.TARGET_ALL,
            Discount_Type__c = Util.Discount.TYPE_PERCENT,
            Value__c = 10.0
        );
        insert d;

        String payload = getCartPayload('01u000000000003AAA', prod.Id, 2, 20.0);
        
        Map<String, Object> result = DiscountService.calculateOrderDiscounts(payload);
        
        System.assertEquals(40.0, result.get('originalTotal'));
        System.assertEquals(4.0, result.get('discountAmount'));
        System.assertEquals(36.0, result.get('finalTotal'));
    }
}