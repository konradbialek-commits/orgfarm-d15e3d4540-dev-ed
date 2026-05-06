public interface DiscountEvaluator {
    Boolean isApplicable(Discount__c discount, OrderContext context);
    Decimal calculateDiscountValue(Discount__c discount, List<DiscountService.CartItem> eligibleItems, Decimal eligibleSubtotal);
}