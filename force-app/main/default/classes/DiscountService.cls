public class DiscountService {
    public static Map<String, Object> calculateOrderDiscounts(Decimal subtotal, Integer totalQuantity) {
        Discount_Setting__c settings = DiscountManagerController.getGlobalSettings();
        OrderContext context = new OrderContext(subtotal, totalQuantity, Date.today());
        
        List<Discount__c> activeDiscounts = [
            SELECT Id, Name, Discount_Category__c, Condition_Type__c, Discount_Type__c, Value__c, Recurrence__c, Custom_Recurrence_Date__c, Minimum_Order_Value__c
            FROM Discount__c 
            WHERE Active__c = true 
            AND (Start_Date__c <= :context.currentDate OR Start_Date__c = null)
            AND (End_Date__c >= :context.currentDate OR End_Date__c = null)
        ];

        List<Discount__c> applicableDiscounts = new List<Discount__c>();
        
        for (Discount__c d : activeDiscounts) {
            String criteria = d.Discount_Category__c == 'Conditional' ? d.Condition_Type__c : d.Recurrence__c;
            
            if (String.isNotBlank(criteria)) {
                DiscountEvaluator evaluator = DiscountEvaluatorFactory.getEvaluator(criteria);
                if (evaluator.isApplicable(d, context)) {
                    applicableDiscounts.add(d);
                }
            } else if (d.Discount_Category__c == 'One Time Only') {
                applicableDiscounts.add(d);
            }
        }

        Decimal totalDiscountAmount = 0;
        List<String> appliedNames = new List<String>();
        List<Id> appliedIds = new List<Id>();

        if (!applicableDiscounts.isEmpty()) {
            if (settings.Strategy__c == 'Cumulative') {
                for (Discount__c d : applicableDiscounts) {
                    appliedNames.add(d.Name);
                    appliedIds.add(d.Id);
                    if (d.Discount_Type__c == 'Percent') {
                        totalDiscountAmount += subtotal * (d.Value__c / 100);
                    } else {
                        totalDiscountAmount += d.Value__c;
                    }
                }
            } else if (settings.Strategy__c == 'Highest' || settings.Strategy__c == 'Lowest') {
                Discount__c selectedDiscount = applicableDiscounts[0];
                
                for (Discount__c d : applicableDiscounts) {
                    Decimal currentVal = d.Discount_Type__c == 'Percent' ? subtotal * (d.Value__c / 100) : d.Value__c;
                    Decimal selectedVal = selectedDiscount.Discount_Type__c == 'Percent' ? subtotal * (selectedDiscount.Value__c / 100) : selectedDiscount.Value__c;
                    
                    if (settings.Strategy__c == 'Highest' && currentVal > selectedVal) selectedDiscount = d;
                    if (settings.Strategy__c == 'Lowest' && currentVal < selectedVal) selectedDiscount = d;
                }
                
                appliedNames.add(selectedDiscount.Name);
                appliedIds.add(selectedDiscount.Id);
                totalDiscountAmount = selectedDiscount.Discount_Type__c == 'Percent' ? subtotal * (selectedDiscount.Value__c / 100) : selectedDiscount.Value__c;
            }
        }

        Decimal minPriceAllowed = subtotal * (settings.Max_Discount_Percent__c / 100);
        Decimal maxDiscountAllowed = subtotal - minPriceAllowed;

        if (totalDiscountAmount > maxDiscountAllowed) {
            totalDiscountAmount = maxDiscountAllowed;
            appliedNames.add('(Price Floor Adjusted)');
        }

        Decimal discountPercent = subtotal > 0 ? (totalDiscountAmount / subtotal) * 100 : 0;

        Map<String, Object> result = new Map<String, Object>();
        result.put('originalTotal', subtotal);
        result.put('discountAmount', totalDiscountAmount);
        result.put('discountPercent', discountPercent.setScale(2));
        result.put('finalTotal', subtotal - totalDiscountAmount);
        result.put('appliedDiscounts', String.join(appliedNames, ', '));
        result.put('appliedDiscountIds', appliedIds);
        
        return result;
    }
}