public class LowestValueStrategy implements DiscountStrategy {
    public List<Discount__c> getWinningDiscounts(List<Discount__c> applicableDiscounts, Map<Id, Decimal> discountToValueMap) {
        if (applicableDiscounts.isEmpty()) return new List<Discount__c>();
        
        Discount__c lowestDiscount = applicableDiscounts[0];
        Decimal lowestVal = discountToValueMap.get(lowestDiscount.Id);
        
        for (Discount__c d : applicableDiscounts) {
            Decimal currentVal = discountToValueMap.get(d.Id);
            if (currentVal < lowestVal) {
                lowestDiscount = d;
                lowestVal = currentVal;
            }
        }
        return new List<Discount__c>{lowestDiscount};
    }
}