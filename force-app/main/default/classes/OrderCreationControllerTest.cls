@IsTest
private class OrderCreationControllerTest {

    @TestSetup
    static void setupTestData() {
        Id stdPricebookId = Test.getStandardPricebookId();

        Account testAccount = new Account(Name = 'BookSmart Test Account');
        insert testAccount;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        );
        insert testOpp;

        Product2 prod1 = new Product2(Name = 'The Great Gatsby', Family = 'Fiction Book', IsActive = true);
        Product2 prod2 = new Product2(Name = 'A Brief History of Time', Family = 'Nonfiction Book', IsActive = true);
        insert new List<Product2>{prod1, prod2};

        PricebookEntry pbe1 = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id = prod1.Id,
            UnitPrice = 10.00,
            IsActive = true
        );
        PricebookEntry pbe2 = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id = prod2.Id,
            UnitPrice = 15.00,
            IsActive = true
        );
        insert new List<PricebookEntry>{pbe1, pbe2};

        Discount__c d = new Discount__c(
            Name = 'One Time 10',
            Active__c = true,
            Discount_Category__c = Util.DISCOUNT.CATEGORY.ONETIME,
            Discount_Type__c = Util.DISCOUNT.DISCOUNT_TYPE.PERCENT_VAL,
            Value__c = 10.0
        );
        insert d;
    }

    @IsTest
    static void testGetAvailablePricebooks() {
        Test.startTest();
        List<Pricebook2> pbs = OrderCreationController.getAvailablePricebooks();
        Test.stopTest();
        
        Assert.isTrue(pbs.size() >= 0, 'Should return a list without throwing errors');
    }

    @IsTest
    static void testGetProductFamilies() {
        Test.startTest();
        List<Map<String, String>> families = OrderCreationController.getProductFamilies();
        Test.stopTest();
        
        Assert.isNotNull(families, 'Should return a list of picklist values');
    }

    @IsTest
    static void testGetProducts() {
        Id stdPricebookId = Test.getStandardPricebookId();
        
        Test.startTest();
        
        List<PricebookEntry> specificResults = OrderCreationController.getProducts('Gatsby', stdPricebookId, '');
        Assert.areEqual(1, specificResults.size(), 'Should find exactly 1 product matching Gatsby');
        
        List<PricebookEntry> allResults = OrderCreationController.getProducts('', stdPricebookId, '');
        Assert.areEqual(2, allResults.size(), 'Should return all active standard products when search is blank');

        List<PricebookEntry> familyResults = OrderCreationController.getProducts('', stdPricebookId, 'Fiction Book');
        Assert.areEqual(1, familyResults.size(), 'Should find exactly 1 product matching Fiction Book family');
        
        List<PricebookEntry> noPbResults = OrderCreationController.getProducts('Gatsby', null, '');
        Assert.areEqual(0, noPbResults.size(), 'Should return 0 products if no pricebook is provided');
        
        Test.stopTest();
    }

    @IsTest
    static void testCreateOrderWithItems() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Id stdPricebookId = Test.getStandardPricebookId();
        PricebookEntry pbe1 = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2.Name = 'The Great Gatsby' LIMIT 1];
        PricebookEntry pbe2 = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2.Name = 'A Brief History of Time' LIMIT 1];
        Discount__c testDiscount = [SELECT Id FROM Discount__c LIMIT 1];

        List<Map<String, Object>> payloadList = new List<Map<String, Object>>();
        
        payloadList.add(new Map<String, Object>{
            'pricebookEntryId' => pbe1.Id,
            'quantity' => 2,
            'unitPrice' => pbe1.UnitPrice
        });
        
        payloadList.add(new Map<String, Object>{
            'pricebookEntryId' => pbe2.Id,
            'quantity' => 1,
            'unitPrice' => pbe2.UnitPrice
        });

        String jsonPayload = JSON.serialize(payloadList);

        Test.startTest();
        Id newOrderId = OrderCreationController.createOrderWithItems(
            opp.Id, 
            jsonPayload, 
            stdPricebookId, 
            10.00, 
            'One Time 10', 
            new List<Id>{testDiscount.Id}
        );
        Test.stopTest();

        Assert.isNotNull(newOrderId, 'Order ID should be returned');

        Order insertedOrder = [SELECT AccountId, OpportunityId, Status, Pricebook2Id, Discount_Amount__c, Applied_Discounts__c FROM Order WHERE Id = :newOrderId];
        Assert.areEqual(opp.AccountId, insertedOrder.AccountId, 'Order should be linked to the correct Account');
        Assert.areEqual(opp.Id, insertedOrder.OpportunityId, 'Order should be linked to the Opportunity');
        Assert.areEqual(Util.ORDER.STATUS.DRAFT, insertedOrder.Status, 'Order status should be Draft via Util');
        Assert.areEqual(stdPricebookId, insertedOrder.Pricebook2Id, 'Pricebook should match the selected one');
        Assert.areEqual(10.00, insertedOrder.Discount_Amount__c, 'Discount amount should be saved');
        Assert.areEqual('One Time 10', insertedOrder.Applied_Discounts__c, 'Applied Discounts should be saved');

        List<OrderItem> insertedItems = [SELECT Quantity, UnitPrice, PricebookEntryId FROM OrderItem WHERE OrderId = :newOrderId ORDER BY Quantity DESC];
        Assert.areEqual(2, insertedItems.size(), 'Should have created exactly 2 Order Items');

        Discount__c updatedDiscount = [SELECT Active__c FROM Discount__c WHERE Id = :testDiscount.Id];
        Assert.isFalse(updatedDiscount.Active__c, 'One Time Only discount should be deactivated');

        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Closed Won', updatedOpp.StageName, 'Opportunity should automatically move to Closed Won');
    }
}