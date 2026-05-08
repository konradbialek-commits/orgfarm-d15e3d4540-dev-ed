@isTest
private class DiscountServiceTest {
    
    @testSetup
    static void setupData() {
        Discount_Setting__c setting = new Discount_Setting__c(
            Name = Util.SETTINGS.DEFAULT_NAME,
            Strategy__c = Util.SETTINGS.STRATEGY.CUMULATIVE,
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
            Discount_Category__c = Util.DISCOUNT.CATEGORY.CONDITIONAL,
            Condition_Type__c = Util.DISCOUNT.CONDITION.TWO_FOR_ONE,
            Target_Type__c = Util.DISCOUNT.TARGET.PRODUCTS,
            Discount_Type__c = Util.DISCOUNT.DISCOUNT_TYPE.PERCENT_VAL,
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
            Discount_Category__c = Util.DISCOUNT.CATEGORY.CONDITIONAL,
            Condition_Type__c = Util.DISCOUNT.CONDITION.MIN_ORDER,
            Minimum_Order_Value__c = 100.0,
            Target_Type__c = Util.DISCOUNT.TARGET.ALL_PRODUCTS,
            Discount_Type__c = Util.DISCOUNT.DISCOUNT_TYPE.FIXED,
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
    static void testVolumeTierEvaluator() {
        Product2 prod = new Product2(Name = 'Bulk Pens', IsActive = true);
        insert prod;

        Discount__c d = new Discount__c(
            Name = 'Buy 10 Get 15% Off',
            Active__c = true,
            Discount_Category__c = Util.DISCOUNT.CATEGORY.CONDITIONAL,
            Condition_Type__c = Util.DISCOUNT.CONDITION.VOLUME,
            Minimum_Quantity__c = 10,
            Target_Type__c = Util.DISCOUNT.TARGET.ALL_PRODUCTS,
            Discount_Type__c = Util.DISCOUNT.DISCOUNT_TYPE.PERCENT_VAL,
            Value__c = 15.0
        );
        insert d;

        String payloadFail = getCartPayload('01u000000000004AAA', prod.Id, 5, 2.0);
        Map<String, Object> resultFail = DiscountService.calculateOrderDiscounts(payloadFail);
        System.assertEquals(0.0, resultFail.get('discountAmount'), 'Should not discount when under minimum quantity');

        String payloadPass = getCartPayload('01u000000000004AAA', prod.Id, 10, 2.0);
        Map<String, Object> resultPass = DiscountService.calculateOrderDiscounts(payloadPass);
        System.assertEquals(3.0, resultPass.get('discountAmount'), 'Should calculate 15% of $20 ($3)');
    }

    @isTest
    static void testRecurringEvaluator() {
        Product2 prod = new Product2(Name = 'Socks', IsActive = true);
        insert prod;

        Discount__c d = new Discount__c(
            Name = 'Daily 10%',
            Active__c = true,
            Discount_Category__c = Util.DISCOUNT.CATEGORY.RECURRING,
            Recurrence__c = 'Daily',
            Target_Type__c = Util.DISCOUNT.TARGET.ALL_PRODUCTS,
            Discount_Type__c = Util.DISCOUNT.DISCOUNT_TYPE.PERCENT_VAL,
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