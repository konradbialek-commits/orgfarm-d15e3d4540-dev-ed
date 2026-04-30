public class DefaultEvaluator implements DiscountEvaluator {
    public Boolean isApplicable(Discount__c d, OrderContext context) {
        return true;
    }
}