public class MinimumOrderValueEvaluator implements DiscountEvaluator {
    public Boolean isApplicable(Discount__c d, OrderContext context) {
        if (d.Minimum_Order_Value__c != null && context.subtotal < d.Minimum_Order_Value__c) {
            return false;
        }
        return true;
    }
}