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
        Opportunity opp = [SELECT AccountId, Pricebook2Id FROM Opportunity WHERE Id = :oppId LIMIT 1];

        Order newOrder = new Order(
            AccountId = opp.AccountId,
            OpportunityId = opp.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Pricebook2Id = opp.Pricebook2Id != null ? opp.Pricebook2Id : [SELECT Id FROM Pricebook2 WHERE IsStandard = true LIMIT 1].Id
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
    }
}