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
                   Target_Type__c, Eligible_Families__c, Minimum_Quantity__c,
                   (SELECT Product__c FROM Discount_Products__r)
            FROM Discount__c 
            WHERE Active__c = true 
            AND (Start_Date__c <= :today OR Start_Date__c = null)
            AND (End_Date__c >= :today OR End_Date__c = null)
        ];

        List<Discount__c> applicableDiscounts = new List<Discount__c>();
        Map<Id, Decimal> discountToValueMap = new Map<Id, Decimal>();
        Map<Id, List<CartItem>> discountToEligibleItems = new Map<Id, List<CartItem>>();
        
        for (Discount__c discount : activeDiscounts) {
            Decimal eligibleSubtotal = 0;
            Integer eligibleQuantity = 0;
            List<CartItem> eligibleItems = new List<CartItem>();
            
            Set<Id> targetedProductIds = new Set<Id>();
            if (discount.Target_Type__c == Util.Discount.TARGET_PRODUCTS) {
                for (Discount_Product__c discountProduct : discount.Discount_Products__r) {
                    targetedProductIds.add(discountProduct.Product__c);
                }
            }

            for (CartItem item : cartItems) {
                Boolean isEligible = false;
                
                if (discount.Target_Type__c == Util.Discount.TARGET_ALL || discount.Target_Type__c == null) {
                    isEligible = true;
                } else if (discount.Target_Type__c == Util.Discount.TARGET_FAMILIES && String.isNotBlank(discount.Eligible_Families__c) && String.isNotBlank(item.family)) {
                    if (discount.Eligible_Families__c.contains(item.family)) {
                        isEligible = true;
                    }
                } else if (discount.Target_Type__c == Util.Discount.TARGET_PRODUCTS) {
                    if (targetedProductIds.contains(item.productId)) {
                        isEligible = true;
                    }
                }
                
                if (isEligible) {
                    eligibleSubtotal += (item.unitPrice * item.quantity);
                    eligibleQuantity += item.quantity;
                    eligibleItems.add(item);
                }
            }

            if (eligibleSubtotal == 0) continue;

            OrderContext context = new OrderContext(subtotal, eligibleSubtotal, eligibleQuantity, today);
            String criteria = discount.Discount_Category__c == Util.Discount.CAT_CONDITIONAL ? discount.Condition_Type__c : discount.Recurrence__c;
            
            Boolean isApplicable = false;
            Decimal discountValue = 0;

            if (String.isNotBlank(criteria)) {
                DiscountEvaluator evaluator = DiscountEvaluatorFactory.getEvaluator(criteria);
                if (evaluator.isApplicable(discount, context)) {
                    isApplicable = true;
                    discountValue = evaluator.calculateDiscountValue(discount, eligibleItems, eligibleSubtotal);
                }
            } else if (discount.Discount_Category__c == Util.Discount.CAT_ONETIME) {
                isApplicable = true;
                discountValue = discount.Discount_Type__c == Util.Discount.TYPE_PERCENT ? eligibleSubtotal * (discount.Value__c / 100) : discount.Value__c;
            }

            if (isApplicable && discountValue > 0) {
                applicableDiscounts.add(discount);
                
                if (discountValue > eligibleSubtotal) {
                    discountValue = eligibleSubtotal;
                }
                discountToValueMap.put(discount.Id, discountValue);
                discountToEligibleItems.put(discount.Id, eligibleItems);
            }
        }

        List<Discount__c> winningDiscounts = new List<Discount__c>();
        if (!applicableDiscounts.isEmpty()) {
            if (settings.Strategy__c == Util.Settings.STRATEGY_CUMULATIVE) {
                winningDiscounts.addAll(applicableDiscounts);
            } else {
                Discount__c selectedDiscount = applicableDiscounts[0];
                Decimal selectedVal = discountToValueMap.get(selectedDiscount.Id);
                
                for (Discount__c discount : applicableDiscounts) {
                    Decimal currentVal = discountToValueMap.get(discount.Id);
                    
                    if (settings.Strategy__c == Util.Settings.STRATEGY_HIGHEST && currentVal > selectedVal) {
                        selectedDiscount = discount;
                        selectedVal = currentVal;
                    }
                    if (settings.Strategy__c == Util.Settings.STRATEGY_LOWEST && currentVal < selectedVal) {
                        selectedDiscount = discount;
                        selectedVal = currentVal;
                    }
                }
                winningDiscounts.add(selectedDiscount);
            }
        }

        Map<String, Decimal> itemDiscounts = new Map<String, Decimal>();
        for (CartItem item : cartItems) {
            itemDiscounts.put((String)item.pricebookEntryId, 0.0);
        }

        Decimal totalDiscountAmount = 0;
        List<String> appliedNames = new List<String>();
        List<Id> appliedIds = new List<Id>();

        for (Discount__c discount : winningDiscounts) {
            appliedNames.add(discount.Name);
            appliedIds.add(discount.Id);
            
            Decimal discountTotalValue = discountToValueMap.get(discount.Id);
            totalDiscountAmount += discountTotalValue;
            
            List<CartItem> eligibleItems = discountToEligibleItems.get(discount.Id);
            Decimal dEligibleSubtotal = 0;
            for (CartItem item : eligibleItems) {
                dEligibleSubtotal += (item.unitPrice * item.quantity);
            }
            
            for (CartItem item : eligibleItems) {
                Decimal itemLineTotal = item.unitPrice * item.quantity;
                Decimal proportion = dEligibleSubtotal > 0 ? (itemLineTotal / dEligibleSubtotal) : 0;
                Decimal itemDiscount = discountTotalValue * proportion;
                
                Decimal currentVal = itemDiscounts.get((String)item.pricebookEntryId);
                itemDiscounts.put((String)item.pricebookEntryId, currentVal + itemDiscount);
            }
        }

        Decimal minPriceAllowed = subtotal * (settings.Minimum_Price_Floor_Percent__c / 100);
        Decimal maxDiscountAllowed = subtotal - minPriceAllowed;

        if (totalDiscountAmount > maxDiscountAllowed) {
            Decimal scaleFactor = totalDiscountAmount > 0 ? (maxDiscountAllowed / totalDiscountAmount) : 0;
            for (String pbeId : itemDiscounts.keySet()) {
                Decimal scaledVal = itemDiscounts.get(pbeId) * scaleFactor;
                itemDiscounts.put(pbeId, scaledVal);
            }
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
        result.put('itemDiscounts', itemDiscounts);
        
        return result;
    }
}