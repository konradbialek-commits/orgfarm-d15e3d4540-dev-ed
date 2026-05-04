public class DefaultEvaluator implements DiscountEvaluator {
    
    public Boolean isApplicable(Discount__c d, OrderContext context) {
        return true; 
    }

    public Decimal calculateDiscountValue(Discount__c d, List<DiscountService.CartItem> eligibleItems, Decimal eligibleSubtotal) {
        return d.Discount_Type__c == Util.Discount.TYPE_PERCENT 
            ? eligibleSubtotal * (d.Value__c / 100) 
            : d.Value__c;
    }
}