@IsTest
private class DiscountStrategyTest {
    
    @IsTest
    static void testFactory() {
        Assert.isTrue(DiscountStrategyFactory.getStrategy(Util.SETTINGS.STRATEGY.CUMULATIVE) instanceof CumulativeStrategy);
        Assert.isTrue(DiscountStrategyFactory.getStrategy(Util.SETTINGS.STRATEGY.HIGHEST) instanceof HighestValueStrategy);
        Assert.isTrue(DiscountStrategyFactory.getStrategy(Util.SETTINGS.STRATEGY.LOWEST) instanceof LowestValueStrategy);
        Assert.isTrue(DiscountStrategyFactory.getStrategy('Gibberish') instanceof CumulativeStrategy);
    }

    @IsTest
    static void testStrategyLogic() {
        Discount__c discount1 = TestDataFactory.createDefaultDiscount();
        discount1.Name = 'Discount 10';
        Discount__c discount2 = TestDataFactory.createDefaultDiscount();
        discount2.Name = 'Discount 50';
        Discount__c discount3 = TestDataFactory.createDefaultDiscount();
        discount3.Name = 'Discount 5';
        insert new List<Discount__c>{discount1, discount2, discount3};
        
        List<Discount__c> applicableDiscounts = new List<Discount__c>{discount1, discount2, discount3};

        Map<Id, Decimal> discountToValueMap = new Map<Id, Decimal>{
            discount1.Id => 10.0,
            discount2.Id => 50.0,
            discount3.Id => 5.0
        };

        DiscountStrategy cumulativeStrat = new CumulativeStrategy();
        List<Discount__c> cumulativeResult = cumulativeStrat.getWinningDiscounts(applicableDiscounts, discountToValueMap);
        Assert.areEqual(3, cumulativeResult.size());

        DiscountStrategy highStrat = new HighestValueStrategy();
        List<Discount__c> highResult = highStrat.getWinningDiscounts(applicableDiscounts, discountToValueMap);
        Assert.areEqual(1, highResult.size());
        Assert.areEqual(discount2.Id, highResult[0].Id);

        DiscountStrategy lowStrat = new LowestValueStrategy();
        List<Discount__c> lowResult = lowStrat.getWinningDiscounts(applicableDiscounts, discountToValueMap);
        Assert.areEqual(1, lowResult.size());
        Assert.areEqual(discount3.Id, lowResult[0].Id);

        List<Discount__c> emptyResult = highStrat.getWinningDiscounts(new List<Discount__c>(), discountToValueMap);
        Assert.areEqual(0, emptyResult.size());
    }
}