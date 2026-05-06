public class MinimumOrderValueEvaluator extends BaseDiscountEvaluator {
    
    public override Boolean isApplicable(Discount__c discount, OrderContext context) {
        return context.eligibleSubtotal >= discount.Minimum_Order_Value__c;
    }
}