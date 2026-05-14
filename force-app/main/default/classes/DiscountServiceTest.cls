@IsTest
private class DiscountServiceTest {
    
    @TestSetup
    static void setupData() {
        insert TestDataFactory.createDefaultDiscountSetting();
    }

    @IsTest
    static void testTwoForOneEvaluatorMath() {
        Product2 prod = TestDataFactory.createDefaultProduct();
        insert prod;
        
        Discount__c discount = TestDataFactory.createDefaultDiscount();
        discount.Name = 'Buy 2 Get 1';
        discount.Discount_Category__c = Util.DISCOUNT.CATEGORY.CONDITIONAL;
        discount.Condition_Type__c = Util.DISCOUNT.CONDITION.TWO_FOR_ONE;
        discount.Target_Type__c = Util.DISCOUNT.TARGET.PRODUCTS;
        discount.Value__c = 100.0;
        insert discount;
        
        insert TestDataFactory.createDiscountProduct(discount.Id, prod.Id);

        String payload = TestDataFactory.createCartPayload('01u000000000001AAA', prod.Id, Util.TEST.PRODUCT.DEFAULT_FAMILY, 50.0, 3);
        
        Map<String, Object> result = DiscountService.calculateOrderDiscounts(payload);
        
        Assert.areEqual(150.0, result.get('originalTotal'));
        Assert.areEqual(50.0, result.get('discountAmount'));
        Assert.areEqual(100.0, result.get('finalTotal'));
    }

    @IsTest
    static void testMinimumOrderEvaluator() {
        Product2 product = TestDataFactory.createDefaultProduct();
        insert product;

        Discount__c discount = TestDataFactory.createDefaultDiscount();
        discount.Name = 'Min 100 Get 20';
        discount.Discount_Category__c = Util.DISCOUNT.CATEGORY.CONDITIONAL;
        discount.Condition_Type__c = Util.DISCOUNT.CONDITION.MIN_ORDER;
        discount.Discount_Type__c = Util.DISCOUNT.DISCOUNT_TYPE.FIXED;
        discount.Minimum_Order_Value__c = 100.0;
        discount.Value__c = 20.0;
        insert discount;

        String payload = TestDataFactory.createCartPayload('01u000000000002AAA', product.Id, Util.TEST.PRODUCT.DEFAULT_FAMILY, 150.0, 1);
        
        Map<String, Object> result = DiscountService.calculateOrderDiscounts(payload);
        
        Assert.areEqual(150.0, result.get('originalTotal'));
        Assert.areEqual(20.0, result.get('discountAmount'));
        Assert.areEqual(130.0, result.get('finalTotal'));
    }

    @IsTest
    static void testVolumeTierEvaluator() {
        Product2 product = TestDataFactory.createDefaultProduct();
        insert product;

        Discount__c discount = TestDataFactory.createDefaultDiscount();
        discount.Name = 'Buy 10 Get 15% Off';
        discount.Discount_Category__c = Util.DISCOUNT.CATEGORY.CONDITIONAL;
        discount.Condition_Type__c = Util.DISCOUNT.CONDITION.VOLUME;
        discount.Minimum_Quantity__c = 10;
        discount.Value__c = 15.0;
        insert discount;

        String payloadFail = TestDataFactory.createCartPayload('01u000000000004AAA', product.Id, Util.TEST.PRODUCT.DEFAULT_FAMILY, 2.0, 5);
        Map<String, Object> resultFail = DiscountService.calculateOrderDiscounts(payloadFail);
        Assert.areEqual(0.0, resultFail.get('discountAmount'));

        String payloadPass = TestDataFactory.createCartPayload('01u000000000004AAA', product.Id, Util.TEST.PRODUCT.DEFAULT_FAMILY, 2.0, 10);
        Map<String, Object> resultPass = DiscountService.calculateOrderDiscounts(payloadPass);
        Assert.areEqual(3.0, resultPass.get('discountAmount'));
    }

    @IsTest
    static void testRecurringEvaluator() {
        Product2 product = TestDataFactory.createDefaultProduct();
        insert product;

        Discount__c discount = TestDataFactory.createDefaultDiscount();
        discount.Name = 'Daily 10%';
        discount.Discount_Category__c = Util.DISCOUNT.CATEGORY.RECURRING;
        discount.Recurrence__c = Util.DISCOUNT.RECURRENCE.DAILY;
        insert discount;

        String payload = TestDataFactory.createCartPayload('01u000000000003AAA', product.Id, Util.TEST.PRODUCT.DEFAULT_FAMILY, 20.0, 2);
        
        Map<String, Object> result = DiscountService.calculateOrderDiscounts(payload);
        
        Assert.areEqual(40.0, result.get('originalTotal'));
        Assert.areEqual(4.0, result.get('discountAmount'));
        Assert.areEqual(36.0, result.get('finalTotal'));
    }
}