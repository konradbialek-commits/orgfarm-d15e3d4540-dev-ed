public with sharing class OrderCreationController {

    @AuraEnabled(cacheable=true)
    public static List<Pricebook2> getAvailablePricebooks() {
        try {
            return [SELECT Id, Name, IsStandard FROM Pricebook2 WHERE IsActive = true];
        } catch (Exception except) {
            ErrorLogger.logException(except, 'OrderCreationController', 'getAvailablePricebooks');
            throw new AuraHandledException(System.Label.Generic_Error_Message);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getProductFamilies() {
        try {
            List<Map<String, String>> options = new List<Map<String, String>>();
            Schema.DescribeFieldResult fieldResult = Product2.Family.getDescribe();
            
            for(Schema.PicklistEntry field : fieldResult.getPicklistValues()) {
                options.add(new Map<String, String>{
                    'label' => field.getLabel(),
                    'value' => field.getValue()
                });
            }
            return options;
        } catch (Exception e) {
            ErrorLogger.logException(e, 'OrderCreationController', 'getProductFamilies');
            throw new AuraHandledException(System.Label.Generic_Error_Message);
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<PricebookEntry> getProducts(String searchTerm, Id pricebookId, String productFamily) {
        try {
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
        } catch (Exception except) {
            ErrorLogger.logException(except, 'OrderCreationController', 'getProducts');
            throw new AuraHandledException(System.Label.Generic_Error_Message);
        }
    }

    @AuraEnabled
    public static Id createOrderWithItems(Id oppId, String productData, Id pricebookId, Decimal discountAmount, String appliedDiscounts, List<Id> appliedDiscountIds) {
        Savepoint savePoint = Database.setSavepoint();
        try {
            Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :oppId LIMIT 1];
            
            opp.StageName = 'Closed Won';
            update opp;
            
            Order newOrder = new Order(
                OpportunityId = opp.Id,
                AccountId = opp.AccountId,
                Pricebook2Id = pricebookId,
                Status = Util.Order.STATUS_DRAFT,
                EffectiveDate = Date.today(),
                Discount_Amount__c = discountAmount,
                Applied_Discounts__c = appliedDiscounts
            );
            insert newOrder;
            
            List<Object> parsedData = (List<Object>) JSON.deserializeUntyped(productData);
            List<OrderItem> itemsToInsert = new List<OrderItem>();
            
            for (Object obj : parsedData) {
                Map<String, Object> item = (Map<String, Object>) obj;
                
                itemsToInsert.add(new OrderItem(
                    OrderId = newOrder.Id,
                    PricebookEntryId = (Id) item.get('pricebookEntryId'),
                    Quantity = Decimal.valueOf(String.valueOf(item.get('quantity'))),
                    UnitPrice = Decimal.valueOf(String.valueOf(item.get('unitPrice')))
                ));
            }
            insert itemsToInsert;
            
            if (appliedDiscountIds != null && !appliedDiscountIds.isEmpty()) {
                List<Discount__c> usedDiscounts = [
                    SELECT Id, Active__c 
                    FROM Discount__c 
                    WHERE Id IN :appliedDiscountIds 
                    AND Discount_Category__c = :Util.Discount.CAT_ONETIME
                ];
                
                if (!usedDiscounts.isEmpty()) {
                    for (Discount__c discount : usedDiscounts) {
                        discount.Active__c = false;
                    }
                    update usedDiscounts;
                }
            }
            
            return newOrder.Id;
        } catch (Exception except) {
            Database.rollback(savePoint);
            ErrorLogger.logException(except, 'OrderCreationController', 'createOrderWithItems');
            throw new AuraHandledException(System.Label.Generic_Error_Message);
        }
    }
}