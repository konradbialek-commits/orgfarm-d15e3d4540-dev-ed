public class TwoForOneEvaluator extends BaseDiscountEvaluator {
    
    public override Boolean isApplicable(Discount__c d, OrderContext context) {
        return context.eligibleQuantity >= 2;
    }

    public override Decimal calculateDiscountValue(Discount__c d, List<DiscountService.CartItem> eligibleItems, Decimal eligibleSubtotal) {
        Decimal discountValue = 0;
        
        for (DiscountService.CartItem item : eligibleItems) {
            Integer freeItemCount = item.quantity / 2;
            discountValue += freeItemCount * item.unitPrice;
        }
        
        return discountValue;
    }
}