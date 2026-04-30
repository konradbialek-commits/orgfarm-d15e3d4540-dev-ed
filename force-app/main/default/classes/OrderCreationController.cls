public with sharing class OrderCreationController {

    @AuraEnabled(cacheable=true)
    public static List<Pricebook2> getAvailablePricebooks() {
        return [SELECT Id, Name, IsStandard FROM Pricebook2 WHERE IsActive = true];
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getProductFamilies() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
        
        for(Schema.PicklistEntry f : fieldResult.getPicklistValues()) {
            options.add(new Map<String, String>{
                'label' => f.getLabel(),
                'value' => f.getValue()
            });
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProducts(String searchTerm, Id pricebookId, String productFamily) {
        String query = 'SELECT Id, Product2Id, Product2.Name, Product2.Family, UnitPrice FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND IsActive = true';
        
        if (String.isNotBlank(searchTerm)) {
            String searchLike = '%' + searchTerm + '%';
            query += ' AND Product2.Name LIKE :searchLike';
        }
        
        if (String.isNotBlank(productFamily)) {
            query += ' AND Product2.Family = :productFamily';
        }
        
        query += ' ORDER BY Product2.Name ASC LIMIT 100';
        return Database.query(query);
    }

    @AuraEnabled
    public static Id createOrderWithItems(Id oppId, String productData, Id pricebookId, Decimal discountAmount, String appliedDiscounts, List<Id> appliedDiscountIds) {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :oppId LIMIT 1];
        
        Order newOrder = new Order(
            OpportunityId = opp.Id,
            AccountId = opp.AccountId,
            Pricebook2Id = pricebookId,
            Status = 'Draft',
            EffectiveDate = Date.today(),
            Total_Discount_Amount__c = discountAmount,
            Applied_Discounts__c = appliedDiscounts
        );
        insert newOrder;
        
        List<Map<String, Object>> parsedData = (List<Map<String, Object>>) JSON.deserializeUntyped(productData);
        List<OrderItem> itemsToInsert = new List<OrderItem>();
        
        for (Map<String, Object> item : parsedData) {
            itemsToInsert.add(new OrderItem(
                OrderId = newOrder.Id,
                PricebookEntryId = (Id) item.get('pricebookEntryId'),
                Quantity = (Decimal) item.get('quantity'),
                UnitPrice = (Decimal) item.get('unitPrice')
            ));
        }
        insert itemsToInsert;
        
        if (appliedDiscountIds != null && !appliedDiscountIds.isEmpty()) {
            List<Discount__c> usedDiscounts = [
                SELECT Id, Active__c 
                FROM Discount__c 
                WHERE Id IN :appliedDiscountIds 
                AND Discount_Category__c = 'One Time Only'
            ];
            
            if (!usedDiscounts.isEmpty()) {
                for (Discount__c d : usedDiscounts) {
                    d.Active__c = false;
                }
                update usedDiscounts;
            }
        }
        
        return newOrder.Id;
    }
}