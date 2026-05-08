public abstract class BaseDiscountEvaluator implements DiscountEvaluator {
    public abstract Boolean isApplicable(Discount__c discount, OrderContext context);
    
    public virtual Decimal calculateDiscountValue(Discount__c discount, List<DiscountService.CartItem> eligibleItems, Decimal eligibleSubtotal) {
        return discount.Discount_Type__c == Util.DISCOUNT.DISCOUNT_TYPE.PERCENT_VAL 
            ? eligibleSubtotal * (discount.Value__c / 100) 
            : discount.Value__c;
    }
}