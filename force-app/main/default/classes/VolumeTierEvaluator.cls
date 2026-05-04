public class VolumeTierEvaluator extends BaseDiscountEvaluator {
    
    public override Boolean isApplicable(Discount__c d, OrderContext context) {
        Decimal requiredQty = d.Minimum_Quantity__c != null ? d.Minimum_Quantity__c : 1;
        
        return context.eligibleQuantity >= requiredQty;
    }
}