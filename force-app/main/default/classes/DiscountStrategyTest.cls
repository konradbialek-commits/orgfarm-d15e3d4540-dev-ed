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
        Discount__c d1 = TestDataFactory.createDefaultDiscount();
        d1.Name = 'Discount 10';
        Discount__c d2 = TestDataFactory.createDefaultDiscount();
        d2.Name = 'Discount 50';
        Discount__c d3 = TestDataFactory.createDefaultDiscount();
        d3.Name = 'Discount 5';
        insert new List<Discount__c>{d1, d2, d3};
        
        List<Discount__c> applicableDiscounts = new List<Discount__c>{d1, d2, d3};

        Map<Id, Decimal> discountToValueMap = new Map<Id, Decimal>{
            d1.Id => 10.0,
            d2.Id => 50.0,
            d3.Id => 5.0
        };

        DiscountStrategy cumStrat = new CumulativeStrategy();
        List<Discount__c> cumResult = cumStrat.getWinningDiscounts(applicableDiscounts, discountToValueMap);
        Assert.areEqual(3, cumResult.size());

        DiscountStrategy highStrat = new HighestValueStrategy();
        List<Discount__c> highResult = highStrat.getWinningDiscounts(applicableDiscounts, discountToValueMap);
        Assert.areEqual(1, highResult.size());
        Assert.areEqual(d2.Id, highResult[0].Id);

        DiscountStrategy lowStrat = new LowestValueStrategy();
        List<Discount__c> lowResult = lowStrat.getWinningDiscounts(applicableDiscounts, discountToValueMap);
        Assert.areEqual(1, lowResult.size());
        Assert.areEqual(d3.Id, lowResult[0].Id);

        List<Discount__c> emptyResult = highStrat.getWinningDiscounts(new List<Discount__c>(), discountToValueMap);
        Assert.areEqual(0, emptyResult.size());
    }
}