public with sharing class OrderCreationController {

    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProducts(String searchTerm) {
        String searchStr = '%' + (String.isBlank(searchTerm) ? '' : searchTerm) + '%';
        
        return [
            SELECT Id, Product2.Name, Product2.Family, UnitPrice
            FROM PricebookEntry
            WHERE Pricebook2.IsStandard = true
              AND Product2.IsActive = true
              AND Product2.Name LIKE :searchStr
            LIMIT 50
        ];
    }

    @AuraEnabled
    public static Id createOrderWithItems(Id oppId, String productData) {
        // Fetch the Opportunity to get the Account ID
        Opportunity opp = [SELECT AccountId, Pricebook2Id FROM Opportunity WHERE Id = :oppId LIMIT 1];

        // 1. Create the Order
        Order newOrder = new Order(
            AccountId = opp.AccountId,
            OpportunityId = opp.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            // Fallback to the Standard Pricebook if the Opp doesn't have one assigned
            Pricebook2Id = opp.Pricebook2Id != null ? opp.Pricebook2Id : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id
        );
        insert newOrder;

        // 2. Parse the JSON payload from the LWC and create Order Items
        List<OrderItem> itemsToInsert = new List<OrderItem>();
        List<Map<String, Object>> parsedData = (List<Map<String, Object>>) JSON.deserializeUntyped(productData);

        for (Map<String, Object> item : parsedData) {
            itemsToInsert.add(new OrderItem(
                OrderId = newOrder.Id,
                PricebookEntryId = (Id)item.get('pricebookEntryId'),
                Quantity = Decimal.valueOf(String.valueOf(item.get('quantity'))),
                UnitPrice = Decimal.valueOf(String.valueOf(item.get('unitPrice')))
            ));
        }
        
        insert itemsToInsert;
        return newOrder.Id;
    }
}