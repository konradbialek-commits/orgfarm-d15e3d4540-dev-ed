public class MinimumOrderValueEvaluator extends BaseDiscountEvaluator {
    
    public override Boolean isApplicable(Discount__c d, OrderContext context) {
        return context.eligibleSubtotal >= d.Minimum_Order_Value__c;
    }
}