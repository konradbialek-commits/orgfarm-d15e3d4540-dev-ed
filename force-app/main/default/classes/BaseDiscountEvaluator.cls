public abstract class BaseDiscountEvaluator implements DiscountEvaluator {
    public abstract Boolean isApplicable(Discount__c d, OrderContext context);
    
    public virtual Decimal calculateDiscountValue(Discount__c d, List<DiscountService.CartItem> eligibleItems, Decimal eligibleSubtotal) {
        return d.Discount_Type__c == Util.Discount.TYPE_PERCENT 
            ? eligibleSubtotal * (d.Value__c / 100) 
            : d.Value__c;
    }
}