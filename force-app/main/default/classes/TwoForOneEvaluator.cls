public class TwoForOneEvaluator implements DiscountEvaluator {
    public Boolean isApplicable(Discount__c d, OrderContext context) {
        return context.eligibleQuantity >= 2;
    }
}