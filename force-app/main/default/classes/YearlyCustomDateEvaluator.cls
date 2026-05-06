public class YearlyCustomDateEvaluator extends BaseDiscountEvaluator {
    
    public override Boolean isApplicable(Discount__c discount, OrderContext context) {
        Date today = context.orderDate != null ? context.orderDate : Date.today();
        return discount.Custom_Recurrence_Date__c != null && 
               today.month() == discount.Custom_Recurrence_Date__c.month() && 
               today.day() == discount.Custom_Recurrence_Date__c.day();
    }
}