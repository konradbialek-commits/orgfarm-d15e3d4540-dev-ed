@IsTest
private class OrderCreationControllerTest {

    @TestSetup
    static void setupTestData() {
        Id stdPricebookId = Test.getStandardPricebookId();

        Account testAccount = TestDataFactory.createAccount(Util.TEST.ORDER.DEFAULT_ACCOUNT_NAME);
        insert testAccount;

        Opportunity testOpp = TestDataFactory.createOpportunity(
            Util.TEST.ORDER.DEFAULT_OPPORTUNITY_NAME,
            Util.TEST.ORDER.DEFAULT_STAGE,
            Date.today().addDays(30),
            testAccount.Id
        );
        insert testOpp;

        Product2 prod1 = TestDataFactory.createDefaultProduct();
        prod1.Name = 'The Great Gatsby';
        prod1.Family = 'Fiction Book';
        
        Product2 prod2 = TestDataFactory.createDefaultProduct();
        prod2.Name = 'A Brief History of Time';
        prod2.Family = 'Nonfiction Book';
        prod2.External_Product_Id__c = 'EXT-STD-001';
        
        insert new List<Product2>{prod1, prod2};

        PricebookEntry priceBookEntry1 = TestDataFactory.createPricebookEntry(stdPricebookId, prod1.Id, 10.00);
        PricebookEntry priceBookEntry2 = TestDataFactory.createPricebookEntry(stdPricebookId, prod2.Id, 15.00);
        insert new List<PricebookEntry>{priceBookEntry1, priceBookEntry2};

        Discount__c discount = TestDataFactory.createDefaultDiscount();
        discount.Name = 'One Time 10';
        insert discount;
    }

    @IsTest
    static void testGetAvailablePricebooks() {
        Test.startTest();
        List<Pricebook2> priceBooks = OrderCreationController.getAvailablePricebooks();
        Test.stopTest();
        
        Assert.isTrue(priceBooks.size() >= 0);
    }

    @IsTest
    static void testGetProductFamilies() {
        Test.startTest();
        List<Map<String, String>> families = OrderCreationController.getProductFamilies();
        Test.stopTest();
        
        Assert.isNotNull(families);
    }

    @IsTest
    static void testGetProducts() {
        Id stdPricebookId = Test.getStandardPricebookId();
        
        Test.startTest();
        
        List<PricebookEntry> specificResults = OrderCreationController.getProducts('Gatsby', stdPricebookId, '');
        Assert.areEqual(1, specificResults.size());
        
        List<PricebookEntry> allResults = OrderCreationController.getProducts('', stdPricebookId, '');
        Assert.areEqual(2, allResults.size());

        List<PricebookEntry> familyResults = OrderCreationController.getProducts('', stdPricebookId, 'Fiction Book');
        Assert.areEqual(1, familyResults.size());
        
        List<PricebookEntry> noPbResults = OrderCreationController.getProducts('Gatsby', null, '');
        Assert.areEqual(0, noPbResults.size());
        
        Test.stopTest();
    }

    @IsTest
    static void testCreateOrderWithItems() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Id stdPricebookId = Test.getStandardPricebookId();
        PricebookEntry priceBookEntry1 = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2.Name = 'The Great Gatsby' LIMIT 1];
        PricebookEntry priceBookEntry2 = [SELECT Id, UnitPrice FROM PricebookEntry WHERE Product2.Name = 'A Brief History of Time' LIMIT 1];
        Discount__c testDiscount = [SELECT Id FROM Discount__c LIMIT 1];

        List<Map<String, Object>> payloadList = new List<Map<String, Object>>();
        
        payloadList.add(new Map<String, Object>{
            'pricebookEntryId' => priceBookEntry1.Id,
            'quantity' => 2,
            'unitPrice' => priceBookEntry1.UnitPrice
        });
        
        payloadList.add(new Map<String, Object>{
            'pricebookEntryId' => priceBookEntry2.Id,
            'quantity' => 1,
            'unitPrice' => priceBookEntry2.UnitPrice
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

        Assert.isNotNull(newOrderId);

        Order insertedOrder = [SELECT AccountId, OpportunityId, Status, Pricebook2Id, Discount_Amount__c, Applied_Discounts__c FROM Order WHERE Id = :newOrderId];
        Assert.areEqual(opp.AccountId, insertedOrder.AccountId);
        Assert.areEqual(opp.Id, insertedOrder.OpportunityId);
        Assert.areEqual(Util.ORDER.STATUS.DRAFT, insertedOrder.Status);
        Assert.areEqual(stdPricebookId, insertedOrder.Pricebook2Id);
        Assert.areEqual(10.00, insertedOrder.Discount_Amount__c);
        Assert.areEqual('One Time 10', insertedOrder.Applied_Discounts__c);

        List<OrderItem> insertedItems = [SELECT Quantity, UnitPrice, PricebookEntryId FROM OrderItem WHERE OrderId = :newOrderId ORDER BY Quantity DESC];
        Assert.areEqual(2, insertedItems.size());

        Discount__c updatedDiscount = [SELECT Active__c FROM Discount__c WHERE Id = :testDiscount.Id];
        Assert.isFalse(updatedDiscount.Active__c);

        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        Assert.areEqual('Closed Won', updatedOpp.StageName);
    }
}