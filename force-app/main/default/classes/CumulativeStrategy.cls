public class CumulativeStrategy implements DiscountStrategy {
    public List<Discount__c> getWinningDiscounts(List<Discount__c> applicableDiscounts, Map<Id, Decimal> discountToValueMap) {
        return new List<Discount__c>(applicableDiscounts);
    }
}