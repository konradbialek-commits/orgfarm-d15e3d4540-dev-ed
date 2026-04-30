public interface DiscountEvaluator {
    Boolean isApplicable(Discount__c d, OrderContext context);
}