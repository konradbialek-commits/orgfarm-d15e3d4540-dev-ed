public class FirstDayOfMonthEvaluator implements DiscountEvaluator {
    public Boolean isApplicable(Discount__c d, OrderContext context) {
        return context.currentDate.day() == 1;
    }
}