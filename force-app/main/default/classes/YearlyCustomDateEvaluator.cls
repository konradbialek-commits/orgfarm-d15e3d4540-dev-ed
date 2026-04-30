public class YearlyCustomDateEvaluator implements DiscountEvaluator {
    public Boolean isApplicable(Discount__c d, OrderContext context) {
        if (d.Custom_Recurrence_Date__c == null) {
            return false;
        }
        return context.currentDate.month() == d.Custom_Recurrence_Date__c.month() 
            && context.currentDate.day() == d.Custom_Recurrence_Date__c.day();
    }
}