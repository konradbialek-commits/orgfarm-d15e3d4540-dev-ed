@isTest
private class DiscountEvaluatorTest {
    
    @isTest
    static void testMinimumOrderValue() {
        Discount__c d = new Discount__c(Minimum_Order_Value__c = 100);
        DiscountEvaluator eval = new MinimumOrderValueEvaluator();

        OrderContext validCtx = new OrderContext(150.0, 150.0, 1, Date.today());
        System.assertEquals(true, eval.isApplicable(d, validCtx));

        OrderContext invalidCtx = new OrderContext(50.0, 50.0, 1, Date.today());
        System.assertEquals(false, eval.isApplicable(d, invalidCtx));
    }

    @isTest
    static void testTwoForOne() {
        Discount__c d = new Discount__c();
        DiscountEvaluator eval = new TwoForOneEvaluator();

        OrderContext validCtx = new OrderContext(100.0, 100.0, 2, Date.today());
        System.assertEquals(true, eval.isApplicable(d, validCtx));

        OrderContext invalidCtx = new OrderContext(100.0, 100.0, 1, Date.today());
        System.assertEquals(false, eval.isApplicable(d, invalidCtx));
    }

    @isTest
    static void testFirstDayOfMonth() {
        Discount__c d = new Discount__c();
        DiscountEvaluator eval = new FirstDayOfMonthEvaluator();

        OrderContext validCtx = new OrderContext(100.0, 100.0, 1, Date.newInstance(2026, 5, 1));
        System.assertEquals(true, eval.isApplicable(d, validCtx));

        OrderContext invalidCtx = new OrderContext(100.0, 100.0, 1, Date.newInstance(2026, 5, 15));
        System.assertEquals(false, eval.isApplicable(d, invalidCtx));
    }

    @isTest
    static void testYearlyCustomDate() {
        Discount__c d = new Discount__c(Custom_Recurrence_Date__c = Date.newInstance(2020, 10, 31));
        DiscountEvaluator eval = new YearlyCustomDateEvaluator();

        OrderContext validCtx = new OrderContext(100.0, 100.0, 1, Date.newInstance(2026, 10, 31));
        System.assertEquals(true, eval.isApplicable(d, validCtx));

        OrderContext invalidCtx = new OrderContext(100.0, 100.0, 1, Date.newInstance(2026, 11, 1));
        System.assertEquals(false, eval.isApplicable(d, invalidCtx));

        Discount__c dNull = new Discount__c();
        System.assertEquals(false, eval.isApplicable(dNull, validCtx));
    }

    @isTest
    static void testFactory() {
        System.assert(DiscountEvaluatorFactory.getEvaluator('Minimum Order Value') instanceof MinimumOrderValueEvaluator);
        System.assert(DiscountEvaluatorFactory.getEvaluator('Two For One') instanceof TwoForOneEvaluator);
        System.assert(DiscountEvaluatorFactory.getEvaluator('First Day of Month') instanceof FirstDayOfMonthEvaluator);
        System.assert(DiscountEvaluatorFactory.getEvaluator('Yearly Custom Date') instanceof YearlyCustomDateEvaluator);
        System.assert(DiscountEvaluatorFactory.getEvaluator('Unknown Criteria') instanceof DefaultEvaluator);
    }
}