@IsTest
private class DiscountEvaluatorTest {
    
    @IsTest
    static void testMinimumOrderValue() {
        Discount__c discount = TestDataFactory.createDefaultDiscount();
        discount.Minimum_Order_Value__c = 100.0;
        DiscountEvaluator eval = new MinimumOrderValueEvaluator();

        OrderContext validCtx = TestDataFactory.createOrderContext(150.0, 150.0, 1, Date.today());
        Assert.isTrue(eval.isApplicable(discount, validCtx));

        OrderContext invalidCtx = TestDataFactory.createOrderContext(50.0, 50.0, 1, Date.today());
        Assert.isFalse(eval.isApplicable(discount, invalidCtx));
    }

    @IsTest
    static void testTwoForOne() {
        Discount__c discount = TestDataFactory.createDefaultDiscount();
        DiscountEvaluator eval = new TwoForOneEvaluator();

        OrderContext validCtx = TestDataFactory.createOrderContext(100.0, 100.0, 2, Date.today());
        Assert.isTrue(eval.isApplicable(discount, validCtx));

        OrderContext invalidCtx = TestDataFactory.createOrderContext(100.0, 100.0, 1, Date.today());
        Assert.isFalse(eval.isApplicable(discount, invalidCtx));
    }

    @IsTest
    static void testFirstDayOfMonth() {
        Discount__c discount = TestDataFactory.createDefaultDiscount();
        DiscountEvaluator eval = new FirstDayOfMonthEvaluator();

        OrderContext validCtx = TestDataFactory.createOrderContext(100.0, 100.0, 1, Date.newInstance(2026, 5, 1));
        Assert.isTrue(eval.isApplicable(discount, validCtx));

        OrderContext invalidCtx = TestDataFactory.createOrderContext(100.0, 100.0, 1, Date.newInstance(2026, 5, 15));
        Assert.isFalse(eval.isApplicable(discount, invalidCtx));
    }

    @IsTest
    static void testYearlyCustomDate() {
        Discount__c discount = TestDataFactory.createDefaultDiscount();
        discount.Custom_Recurrence_Date__c = Date.newInstance(2020, 10, 31);
        DiscountEvaluator eval = new YearlyCustomDateEvaluator();

        OrderContext validCtx = TestDataFactory.createOrderContext(100.0, 100.0, 1, Date.newInstance(2026, 10, 31));
        Assert.isTrue(eval.isApplicable(discount, validCtx));

        OrderContext invalidCtx = TestDataFactory.createOrderContext(100.0, 100.0, 1, Date.newInstance(2026, 11, 1));
        Assert.isFalse(eval.isApplicable(discount, invalidCtx));

        Discount__c dNull = TestDataFactory.createDefaultDiscount();
        Assert.isFalse(eval.isApplicable(dNull, validCtx));
    }

    @IsTest
    static void testFactory() {
        Assert.isTrue(DiscountEvaluatorFactory.getEvaluator('Minimum Order Value') instanceof MinimumOrderValueEvaluator);
        Assert.isTrue(DiscountEvaluatorFactory.getEvaluator('Two For One') instanceof TwoForOneEvaluator);
        Assert.isTrue(DiscountEvaluatorFactory.getEvaluator('First Day of Month') instanceof FirstDayOfMonthEvaluator);
        Assert.isTrue(DiscountEvaluatorFactory.getEvaluator('Yearly Custom Date') instanceof YearlyCustomDateEvaluator);
        Assert.isTrue(DiscountEvaluatorFactory.getEvaluator('Unknown Criteria') instanceof DefaultEvaluator);
    }
}