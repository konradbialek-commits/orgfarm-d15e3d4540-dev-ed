public interface DiscountEvaluator {
    Boolean isApplicable(Discount__c d, OrderContext context);
    Decimal calculateDiscountValue(Discount__c d, List<DiscountService.CartItem> eligibleItems, Decimal eligibleSubtotal);
}