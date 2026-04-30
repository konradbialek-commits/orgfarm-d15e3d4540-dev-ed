public class DiscountService {
    
    public class CartItem {
        public Id pricebookEntryId;
        public Id productId;
        public String family;
        public Decimal unitPrice;
        public Integer quantity;
    }

    public static Map<String, Object> calculateOrderDiscounts(String cartPayload) {
        List<CartItem> cartItems = (List<CartItem>)JSON.deserialize(cartPayload, List<CartItem>.class);
        
        Decimal subtotal = 0;
        for (CartItem item : cartItems) {
            subtotal += (item.unitPrice * item.quantity);
        }

        Discount_Setting__c settings = DiscountManagerController.getGlobalSettings();
        Date today = Date.today();
        
        List<Discount__c> activeDiscounts = [
            SELECT Id, Name, Discount_Category__c, Condition_Type__c, Discount_Type__c, 
                   Value__c, Recurrence__c, Custom_Recurrence_Date__c, Minimum_Order_Value__c,
                   Target_Type__c, Eligible_Families__c,
                   (SELECT Product__c FROM Discount_Products__r)
            FROM Discount__c 
            WHERE Active__c = true 
            AND (Start_Date__c <= :today OR Start_Date__c = null)
            AND (End_Date__c >= :today OR End_Date__c = null)
        ];

        List<Discount__c> applicableDiscounts = new List<Discount__c>();
        Map<Id, Decimal> discountToValueMap = new Map<Id, Decimal>();
        
        for (Discount__c d : activeDiscounts) {
            Decimal eligibleSubtotal = 0;
            Integer eligibleQuantity = 0;
            
            Set<Id> targetedProductIds = new Set<Id>();
            if (d.Target_Type__c == 'Specific Products') {
                for (Discount_Product__c dp : d.Discount_Products__r) {
                    targetedProductIds.add(dp.Product__c);
                }
            }

            for (CartItem item : cartItems) {
                Boolean isEligible = false;
                
                if (d.Target_Type__c == 'All Products' || d.Target_Type__c == null) {
                    isEligible = true;
                } else if (d.Target_Type__c == 'Specific Families' && String.isNotBlank(d.Eligible_Families__c) && String.isNotBlank(item.family)) {
                    if (d.Eligible_Families__c.contains(item.family)) {
                        isEligible = true;
                    }
                } else if (d.Target_Type__c == 'Specific Products') {
                    if (targetedProductIds.contains(item.productId)) {
                        isEligible = true;
                    }
                }
                
                if (isEligible) {
                    eligibleSubtotal += (item.unitPrice * item.quantity);
                    eligibleQuantity += item.quantity;
                }
            }

            if (eligibleSubtotal == 0) continue;

            OrderContext context = new OrderContext(subtotal, eligibleSubtotal, eligibleQuantity, today);
            
            String criteria = d.Discount_Category__c == 'Conditional' ? d.Condition_Type__c : d.Recurrence__c;
            
            Boolean isApplicable = false;
            if (String.isNotBlank(criteria)) {
                DiscountEvaluator evaluator = DiscountEvaluatorFactory.getEvaluator(criteria);
                if (evaluator.isApplicable(d, context)) {
                    isApplicable = true;
                }
            } else if (d.Discount_Category__c == 'One Time Only') {
                isApplicable = true;
            }

            if (isApplicable) {
                applicableDiscounts.add(d);
                Decimal dValue = d.Discount_Type__c == 'Percent' ? eligibleSubtotal * (d.Value__c / 100) : d.Value__c;
                
                if (dValue > eligibleSubtotal) {
                    dValue = eligibleSubtotal;
                }
                discountToValueMap.put(d.Id, dValue);
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
                    totalDiscountAmount += discountToValueMap.get(d.Id);
                }
            } else if (settings.Strategy__c == 'Highest' || settings.Strategy__c == 'Lowest') {
                Discount__c selectedDiscount = applicableDiscounts[0];
                Decimal selectedVal = discountToValueMap.get(selectedDiscount.Id);
                
                for (Discount__c d : applicableDiscounts) {
                    Decimal currentVal = discountToValueMap.get(d.Id);
                    
                    if (settings.Strategy__c == 'Highest' && currentVal > selectedVal) {
                        selectedDiscount = d;
                        selectedVal = currentVal;
                    }
                    if (settings.Strategy__c == 'Lowest' && currentVal < selectedVal) {
                        selectedDiscount = d;
                        selectedVal = currentVal;
                    }
                }
                
                appliedNames.add(selectedDiscount.Name);
                appliedIds.add(selectedDiscount.Id);
                totalDiscountAmount = selectedVal;
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