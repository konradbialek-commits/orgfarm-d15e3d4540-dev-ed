public class HighestValueStrategy implements DiscountStrategy {
    public List<Discount__c> getWinningDiscounts(List<Discount__c> applicableDiscounts, Map<Id, Decimal> discountToValueMap) {
        if (applicableDiscounts.isEmpty()) return new List<Discount__c>();
        
        Discount__c bestDiscount = applicableDiscounts[0];
        Decimal highestVal = discountToValueMap.get(bestDiscount.Id);
        
        for (Discount__c d : applicableDiscounts) {
            Decimal currentVal = discountToValueMap.get(d.Id);
            if (currentVal > highestVal) {
                bestDiscount = d;
                highestVal = currentVal;
            }
        }
        return new List<Discount__c>{bestDiscount};
    }
}