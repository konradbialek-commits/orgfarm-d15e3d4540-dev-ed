@isTest
private class DiscountStrategyTest {
    
    @isTest
    static void testFactory() {
        System.assert(DiscountStrategyFactory.getStrategy(Util.SETTINGS.STRATEGY.CUMULATIVE) instanceof CumulativeStrategy, 'Should return Cumulative');
        System.assert(DiscountStrategyFactory.getStrategy(Util.SETTINGS.STRATEGY.HIGHEST) instanceof HighestValueStrategy, 'Should return Highest');
        System.assert(DiscountStrategyFactory.getStrategy(Util.SETTINGS.STRATEGY.LOWEST) instanceof LowestValueStrategy, 'Should return Lowest');
        System.assert(DiscountStrategyFactory.getStrategy('Gibberish') instanceof CumulativeStrategy, 'Should default to Cumulative');
    }

    @isTest
    static void testStrategyLogic() {
        Discount__c d1 = new Discount__c(Name = 'Discount 10');
        Discount__c d2 = new Discount__c(Name = 'Discount 50');
        Discount__c d3 = new Discount__c(Name = 'Discount 5');
        insert new List<Discount__c>{d1, d2, d3};
        
        List<Discount__c> applicableDiscounts = new List<Discount__c>{d1, d2, d3};

        Map<Id, Decimal> discountToValueMap = new Map<Id, Decimal>{
            d1.Id => 10.0,
            d2.Id => 50.0,
            d3.Id => 5.0
        };

        DiscountStrategy cumStrat = new CumulativeStrategy();
        List<Discount__c> cumResult = cumStrat.getWinningDiscounts(applicableDiscounts, discountToValueMap);
        System.assertEquals(3, cumResult.size(), 'Cumulative should return all applicable discounts');

        DiscountStrategy highStrat = new HighestValueStrategy();
        List<Discount__c> highResult = highStrat.getWinningDiscounts(applicableDiscounts, discountToValueMap);
        System.assertEquals(1, highResult.size(), 'Highest should only return one winner');
        System.assertEquals(d2.Id, highResult[0].Id, 'Highest should select the $50 discount');

        DiscountStrategy lowStrat = new LowestValueStrategy();
        List<Discount__c> lowResult = lowStrat.getWinningDiscounts(applicableDiscounts, discountToValueMap);
        System.assertEquals(1, lowResult.size(), 'Lowest should only return one winner');
        System.assertEquals(d3.Id, lowResult[0].Id, 'Lowest should select the $5 discount');

        List<Discount__c> emptyResult = highStrat.getWinningDiscounts(new List<Discount__c>(), discountToValueMap);
        System.assertEquals(0, emptyResult.size(), 'Should handle empty lists gracefully');
    }
}