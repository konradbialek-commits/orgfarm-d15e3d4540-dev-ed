@IsTest
private class DiscountEvaluatorTest {
    @TestSetup
    static void setupData() {
        Discount__c discount1 = TestDataFactory.createDefaultDiscount();
        discount1.Name = 'MinOrder';
        discount1.Minimum_Order_Value__c = 100.0;

        Discount__c discount2 = TestDataFactory.createDefaultDiscount();
        discount2.Name = 'TwoForOne';

        Discount__c discount3 = TestDataFactory.createDefaultDiscount();
        discount3.Name = 'FirstDay';

        Discount__c discount4 = TestDataFactory.createDefaultDiscount();
        discount4.Name = 'YearlyCustom';
        discount4.Custom_Recurrence_Date__c = Date.newInstance(2020, 10, 31);

        insert new List<Discount__c>{ discount1, discount2, discount3, discount4 };
    }

    @IsTest
    static void testMinimumOrderValue() {
        Discount__c discount = [
            SELECT Id, Minimum_Order_Value__c, Discount_Type__c, Value__c
            FROM Discount__c
            WHERE Name = 'MinOrder'
            LIMIT 1
        ];
        DiscountEvaluator eval = new MinimumOrderValueEvaluator();

        OrderContext validCtx = TestDataFactory.createOrderContext(150.0, 150.0, 1, Date.today());
        Assert.isTrue(eval.isApplicable(discount, validCtx));

        OrderContext invalidCtx = TestDataFactory.createOrderContext(50.0, 50.0, 1, Date.today());
        Assert.isFalse(eval.isApplicable(discount, invalidCtx));
    }

    @IsTest
    static void testTwoForOne() {
        Discount__c discount = [SELECT Id, Discount_Type__c, Value__c FROM Discount__c WHERE Name = 'TwoForOne' LIMIT 1];
        DiscountEvaluator eval = new TwoForOneEvaluator();

        OrderContext validCtx = TestDataFactory.createOrderContext(100.0, 100.0, 2, Date.today());
        Assert.isTrue(eval.isApplicable(discount, validCtx));

        OrderContext invalidCtx = TestDataFactory.createOrderContext(100.0, 100.0, 1, Date.today());
        Assert.isFalse(eval.isApplicable(discount, invalidCtx));
    }

    @IsTest
    static void testFirstDayOfMonth() {
        Discount__c discount = [SELECT Id, Discount_Type__c, Value__c FROM Discount__c WHERE Name = 'FirstDay' LIMIT 1];
        DiscountEvaluator eval = new FirstDayOfMonthEvaluator();

        OrderContext validCtx = TestDataFactory.createOrderContext(100.0, 100.0, 1, Date.newInstance(2026, 5, 1));
        Assert.isTrue(eval.isApplicable(discount, validCtx));

        OrderContext invalidCtx = TestDataFactory.createOrderContext(100.0, 100.0, 1, Date.newInstance(2026, 5, 15));
        Assert.isFalse(eval.isApplicable(discount, invalidCtx));
    }

    @IsTest
    static void testYearlyCustomDate() {
        Discount__c discount = [
            SELECT Id, Custom_Recurrence_Date__c, Discount_Type__c, Value__c
            FROM Discount__c
            WHERE Name = 'YearlyCustom'
            LIMIT 1
        ];
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
