public class FirstDayOfMonthEvaluator extends BaseDiscountEvaluator {
    
    public override Boolean isApplicable(Discount__c discount, OrderContext context) {
        Date today = context.orderDate != null ? context.orderDate : Date.today();
        return today.day() == 1;
    }
}