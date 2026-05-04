public class YearlyCustomDateEvaluator extends BaseDiscountEvaluator {
    
    public override Boolean isApplicable(Discount__c d, OrderContext context) {
        Date today = context.orderDate != null ? context.orderDate : Date.today();
        return d.Custom_Recurrence_Date__c != null && 
               today.month() == d.Custom_Recurrence_Date__c.month() && 
               today.day() == d.Custom_Recurrence_Date__c.day();
    }
}