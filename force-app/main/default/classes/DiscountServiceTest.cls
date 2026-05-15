@IsTest
private class DiscountServiceTest {
    @TestSetup
    static void setupData() {
        insert TestDataFactory.createDefaultDiscountSetting();

        Product2 prod = TestDataFactory.createDefaultProduct();
        insert prod;

        Discount__c discount1 = TestDataFactory.createDiscount(
            'Buy 2 Get 1',
            true,
            Util.DISCOUNT.CATEGORY.CONDITIONAL,
            Util.DISCOUNT.DISCOUNT_TYPE.PERCENT_VAL,
            100.0,
            Util.DISCOUNT.TARGET.PRODUCTS
        );
        discount1.Condition_Type__c = Util.DISCOUNT.CONDITION.TWO_FOR_ONE;

        Discount__c discount2 = TestDataFactory.createDiscount(
            'Min 100 Get 20',
            true,
            Util.DISCOUNT.CATEGORY.CONDITIONAL,
            Util.DISCOUNT.DISCOUNT_TYPE.FIXED,
            20.0,
            Util.DISCOUNT.TARGET.ALL_PRODUCTS
        );
        discount2.Condition_Type__c = Util.DISCOUNT.CONDITION.MIN_ORDER;
        discount2.Minimum_Order_Value__c = 100.0;

        Discount__c discount3 = TestDataFactory.createDiscount(
            'Buy 10 Get 15% Off',
            true,
            Util.DISCOUNT.CATEGORY.CONDITIONAL,
            Util.DISCOUNT.DISCOUNT_TYPE.PERCENT_VAL,
            15.0,
            Util.DISCOUNT.TARGET.ALL_PRODUCTS
        );
        discount3.Condition_Type__c = Util.DISCOUNT.CONDITION.VOLUME;
        discount3.Minimum_Quantity__c = 10;

        Discount__c discount4 = TestDataFactory.createDiscount(
            'Daily 10%',
            true,
            Util.DISCOUNT.CATEGORY.RECURRING,
            Util.DISCOUNT.DISCOUNT_TYPE.PERCENT_VAL,
            10.0,
            Util.DISCOUNT.TARGET.ALL_PRODUCTS
        );
        discount4.Recurrence__c = Util.DISCOUNT.RECURRENCE.DAILY;

        insert new List<Discount__c>{ discount1, discount2, discount3, discount4 };
        insert TestDataFactory.createDiscountProduct(discount1.Id, prod.Id);
    }

    @IsTest
    static void testTwoForOneEvaluatorMath() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        String payload = TestDataFactory.createCartPayload('01u000000000001AAA', prod.Id, Util.TEST.PRODUCT.DEFAULT_FAMILY, 50.0, 3);

        Test.startTest();
        Map<String, Object> result = DiscountService.calculateOrderDiscounts(payload);
        Test.stopTest();

        Assert.areEqual(150.0, result.get('originalTotal'));
        Assert.areEqual(50.0, result.get('discountAmount'));
        Assert.areEqual(100.0, result.get('finalTotal'));
    }

    @IsTest
    static void testMinimumOrderEvaluator() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        String payload = TestDataFactory.createCartPayload('01u000000000002AAA', prod.Id, Util.TEST.PRODUCT.DEFAULT_FAMILY, 150.0, 1);

        Test.startTest();
        Map<String, Object> result = DiscountService.calculateOrderDiscounts(payload);
        Test.stopTest();

        Assert.areEqual(150.0, result.get('originalTotal'));
        Assert.areEqual(20.0, result.get('discountAmount'));
        Assert.areEqual(130.0, result.get('finalTotal'));
    }

    @IsTest
    static void testVolumeTierEvaluator() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        String payloadFail = TestDataFactory.createCartPayload('01u000000000004AAA', prod.Id, Util.TEST.PRODUCT.DEFAULT_FAMILY, 2.0, 5);
        String payloadPass = TestDataFactory.createCartPayload('01u000000000004AAA', prod.Id, Util.TEST.PRODUCT.DEFAULT_FAMILY, 2.0, 10);

        Test.startTest();
        Map<String, Object> resultFail = DiscountService.calculateOrderDiscounts(payloadFail);
        Map<String, Object> resultPass = DiscountService.calculateOrderDiscounts(payloadPass);
        Test.stopTest();

        Assert.areEqual(0.0, resultFail.get('discountAmount'));
        Assert.areEqual(3.0, resultPass.get('discountAmount'));
    }

    @IsTest
    static void testRecurringEvaluator() {
        Product2 prod = [SELECT Id FROM Product2 LIMIT 1];
        String payload = TestDataFactory.createCartPayload('01u000000000003AAA', prod.Id, Util.TEST.PRODUCT.DEFAULT_FAMILY, 20.0, 2);

        Test.startTest();
        Map<String, Object> result = DiscountService.calculateOrderDiscounts(payload);
        Test.stopTest();

        Assert.areEqual(40.0, result.get('originalTotal'));
        Assert.areEqual(4.0, result.get('discountAmount'));
        Assert.areEqual(36.0, result.get('finalTotal'));
    }
}
