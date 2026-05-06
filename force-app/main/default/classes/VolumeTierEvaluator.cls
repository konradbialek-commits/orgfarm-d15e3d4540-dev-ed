public class VolumeTierEvaluator extends BaseDiscountEvaluator {
    
    public override Boolean isApplicable(Discount__c discount, OrderContext context) {
        Decimal requiredQty = discount.Minimum_Quantity__c != null ? discount.Minimum_Quantity__c : 1;
        
        return context.eligibleQuantity >= requiredQty;
    }
}