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
            AccountId = testAccount.Id,
            Pricebook2Id = stdPricebookId
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
    }

    @IsTest
    static void testGetProducts() {
        Test.startTest();
        List<PricebookEntry> specificResults = OrderCreationController.getProducts('Gatsby');
        Assert.areEqual(1, specificResults.size(), 'Should find exactly 1 product matching Gatsby');
        
        List<PricebookEntry> allResults = OrderCreationController.getProducts('');
        Assert.areEqual(2, allResults.size(), 'Should return all active standard products when search is blank');
        
        Test.stopTest();
    }

    @IsTest
    static void testCreateOrderWithItems() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        PricebookEntry pbe1 = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2.Name = 'The Great Gatsby' LIMIT 1];
        PricebookEntry pbe2 = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2.Name = 'A Brief History of Time' LIMIT 1];

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
        Id newOrderId = OrderCreationController.createOrderWithItems(opp.Id, jsonPayload);
        Test.stopTest();

        Assert.isNotNull(newOrderId, 'Order ID should be returned');

        Order insertedOrder = [SELECT AccountId, OpportunityId, Status, Pricebook2Id FROM Order WHERE Id = :newOrderId];
        Assert.areEqual(opp.AccountId, insertedOrder.AccountId, 'Order should be linked to the correct Account');
        Assert.areEqual(opp.Id, insertedOrder.OpportunityId, 'Order should be linked to the Opportunity');
        Assert.areEqual('Draft', insertedOrder.Status, 'Order status should be Draft');

        List<OrderItem> insertedItems = [SELECT Quantity, UnitPrice, PricebookEntryId FROM OrderItem WHERE OrderId = :newOrderId ORDER BY Quantity DESC];
        Assert.areEqual(2, insertedItems.size(), 'Should have created exactly 2 Order Items');
        
        Assert.areEqual(2, insertedItems[0].Quantity, 'First item quantity should be 2');
        Assert.areEqual(pbe1.Id, insertedItems[0].PricebookEntryId, 'PricebookEntry ID should match');
    }
}