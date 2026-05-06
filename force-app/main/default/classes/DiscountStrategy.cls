public interface DiscountStrategy {
    List<Discount__c> getWinningDiscounts(List<Discount__c> applicableDiscounts, Map<Id, Decimal> discountToValueMap);
}