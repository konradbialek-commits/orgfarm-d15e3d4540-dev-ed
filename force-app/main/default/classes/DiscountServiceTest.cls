@isTest
private class DiscountServiceTest {
    
    @testSetup
    static void setupData() {
        Discount_Setting__c setting = new Discount_Setting__c(
            Name = Util.Settings.DEFAULT_NAME,
            Strategy__c = Util.Settings.STRATEGY_CUMULATIVE,
            Max_Discount_Percent__c = 20.0
        );
        insert setting;

        List<Discount__c> discounts = new List<Discount__c>();
        
        discounts.add(new Discount__c(
            Name = '10 Percent Off',
            Active__c = true,
            Discount_Category__c = Util.Discount.CAT_ONETIME,
            Target_Type__c = Util.Discount.TARGET_ALL,
            Discount_Type__c = Util.Discount.TYPE_PERCENT,
            Value__c = 10.0
        ));

        discounts.add(new Discount__c(
            Name = '15 Fixed Off',
            Active__c = true,
            Discount_Category__c = Util.Discount.CAT_CONDITIONAL,
            Condition_Type__c = Util.Discount.COND_MIN_ORDER,
            Minimum_Order_Value__c = 50.0,
            Target_Type__c = Util.Discount.TARGET_ALL,
            Discount_Type__c = Util.Discount.TYPE_FIXED,
            Value__c = 15.0
        ));

        insert discounts;
    }

    static String getCartPayload() {
        return '[{"pricebookEntryId":"01u000000000000AAA","productId":"01t000000000000AAA","family":"Test","unitPrice":100.0,"quantity":1}]';
    }

    @isTest
    static void testCalculateOrderDiscountsCumulative() {
        Map<String, Object> result = DiscountService.calculateOrderDiscounts(getCartPayload());
        
        System.assertEquals(100.0, result.get('originalTotal'));
        System.assertEquals(25.0, result.get('discountAmount'));
        System.assertEquals(75.0, result.get('finalTotal'));
        
        Map<String, Decimal> itemDiscounts = (Map<String, Decimal>) result.get('itemDiscounts');
        System.assertEquals(25.0, itemDiscounts.get('01u000000000000AAA'));
    }

    @isTest
    static void testHighestStrategy() {
        Discount_Setting__c setting = [SELECT Id FROM Discount_Setting__c LIMIT 1];
        setting.Strategy__c = Util.Settings.STRATEGY_HIGHEST;
        update setting;

        Map<String, Object> result = DiscountService.calculateOrderDiscounts(getCartPayload());
        
        System.assertEquals(15.0, result.get('discountAmount'));
        System.assertEquals(85.0, result.get('finalTotal'));
        
        Map<String, Decimal> itemDiscounts = (Map<String, Decimal>) result.get('itemDiscounts');
        System.assertEquals(15.0, itemDiscounts.get('01u000000000000AAA'));
    }

    @isTest
    static void testLowestStrategy() {
        Discount_Setting__c setting = [SELECT Id FROM Discount_Setting__c LIMIT 1];
        setting.Strategy__c = Util.Settings.STRATEGY_LOWEST;
        update setting;

        Map<String, Object> result = DiscountService.calculateOrderDiscounts(getCartPayload());
        
        System.assertEquals(10.0, result.get('discountAmount'));
        System.assertEquals(90.0, result.get('finalTotal'));
        
        Map<String, Decimal> itemDiscounts = (Map<String, Decimal>) result.get('itemDiscounts');
        System.assertEquals(10.0, itemDiscounts.get('01u000000000000AAA'));
    }

    @isTest
    static void testMaxDiscountFloor() {
        Discount_Setting__c setting = [SELECT Id FROM Discount_Setting__c LIMIT 1];
        setting.Strategy__c = Util.Settings.STRATEGY_CUMULATIVE;
        setting.Max_Discount_Percent__c = 80.0;
        update setting;

        Map<String, Object> result = DiscountService.calculateOrderDiscounts(getCartPayload());
        
        System.assertEquals(20.0, result.get('discountAmount')); 
        System.assertEquals(80.0, result.get('finalTotal'));
        
        Map<String, Decimal> itemDiscounts = (Map<String, Decimal>) result.get('itemDiscounts');
        System.assertEquals(20.0, itemDiscounts.get('01u000000000000AAA'));
    }

    @isTest
    static void testTargetedLineItemDiscount() {
        delete [SELECT Id FROM Discount__c];
        
        Discount_Setting__c setting = [SELECT Id FROM Discount_Setting__c LIMIT 1];
        setting.Strategy__c = Util.Settings.STRATEGY_CUMULATIVE;
        setting.Max_Discount_Percent__c = 0.0;
        update setting;

        Product2 prod1 = new Product2(Name = 'Product 1', IsActive = true);
        Product2 prod2 = new Product2(Name = 'Product 2', IsActive = true);
        insert new List<Product2>{prod1, prod2};

        String pbe1 = '01u000000000001AAA';
        String pbe2 = '01u000000000002AAA';

        String multiCart = '[' +
            '{"pricebookEntryId":"' + pbe1 + '","productId":"' + prod1.Id + '","family":"","unitPrice":100.0,"quantity":1},' +
            '{"pricebookEntryId":"' + pbe2 + '","productId":"' + prod2.Id + '","family":"","unitPrice":50.0,"quantity":2}' +
        ']';

        Discount__c targetedDiscount = new Discount__c(
            Name = 'Prod 2 Only 50 Off',
            Active__c = true,
            Discount_Category__c = Util.Discount.CAT_ONETIME,
            Target_Type__c = Util.Discount.TARGET_PRODUCTS,
            Discount_Type__c = Util.Discount.TYPE_FIXED,
            Value__c = 50.0
        );
        insert targetedDiscount;

        insert new Discount_Product__c(
            Discount__c = targetedDiscount.Id,
            Product__c = prod2.Id
        );

        Map<String, Object> result = DiscountService.calculateOrderDiscounts(multiCart);
        
        System.assertEquals(200.0, result.get('originalTotal'));
        System.assertEquals(50.0, result.get('discountAmount'));
        System.assertEquals(150.0, result.get('finalTotal'));

        Map<String, Decimal> itemDiscounts = (Map<String, Decimal>) result.get('itemDiscounts');
        
        System.assertEquals(0.0, itemDiscounts.get(pbe1)); 
        System.assertEquals(50.0, itemDiscounts.get(pbe2));
    }
}