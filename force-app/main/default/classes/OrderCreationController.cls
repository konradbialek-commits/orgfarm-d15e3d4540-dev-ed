public with sharing class OrderCreationController {

    @AuraEnabled(cacheable=true)
    public static List<Pricebook2> getAvailablePricebooks() {
        return [SELECT Id, Name, IsStandard FROM Pricebook2 WHERE IsActive = true ORDER BY Name ASC];
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getProductFamilies() {
        List<Map<String, String>> options = new List<Map<String, String>>();
        Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry f : ple) {
            options.add(new Map<String, String>{
                'label' => f.getLabel(),
                'value' => f.getValue()
            });
        }
        return options;
    }

    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProducts(String searchTerm, Id pricebookId, String productFamily) {
        if (String.isBlank(pricebookId)) {
            return new List<PricebookEntry>();
        }

        String searchStr = '%' + (String.isBlank(searchTerm) ? '' : searchTerm) + '%';
        
        String query = 'SELECT Id, Product2.Name, Product2.Family, UnitPrice FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2.IsActive = true AND Product2.Name LIKE :searchStr';
        
        if (String.isNotBlank(productFamily)) {
            query += ' AND Product2.Family = :productFamily';
        }
        
        query += ' LIMIT 50';
        
        return Database.query(query);
    }

    @AuraEnabled
    public static Id createOrderWithItems(Id oppId, String productData, Id pricebookId, Decimal discountAmount, String appliedDiscounts) {
        try {
            Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id = :oppId LIMIT 1];

            Order newOrder = new Order(
                AccountId = opp.AccountId,
                OpportunityId = opp.Id,
                EffectiveDate = Date.today(),
                Status = 'Draft',
                Pricebook2Id = pricebookId,
                Discount_Amount__c = discountAmount,
                Applied_Discounts__c = appliedDiscounts
            );
            insert newOrder;

            List<OrderItem> itemsToInsert = new List<OrderItem>();
            
            List<Object> parsedData = (List<Object>) JSON.deserializeUntyped(productData);

            for (Object obj : parsedData) {
                Map<String, Object> item = (Map<String, Object>) obj;
                
                itemsToInsert.add(new OrderItem(
                    OrderId = newOrder.Id,
                    PricebookEntryId = (Id)item.get('pricebookEntryId'),
                    Quantity = Decimal.valueOf(String.valueOf(item.get('quantity'))),
                    UnitPrice = Decimal.valueOf(String.valueOf(item.get('unitPrice')))
                ));
            }
            
            insert itemsToInsert;
            return newOrder.Id;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}