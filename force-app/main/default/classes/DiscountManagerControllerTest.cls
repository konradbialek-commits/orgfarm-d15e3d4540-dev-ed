@IsTest
private class DiscountManagerControllerTest {
    
    @IsTest
    static void testGlobalSettingsRetrievedAndSaved() {
        Discount_Setting__c setting = DiscountManagerController.getGlobalSettings();
        Assert.isNotNull(setting);

        setting.Minimum_Price_Floor_Percent__c = 5.0;
        DiscountManagerController.saveGlobalSettings(setting);
        
        Discount_Setting__c updatedSetting = DiscountManagerController.getGlobalSettings();
        Assert.areEqual(5.0, updatedSetting.Minimum_Price_Floor_Percent__c);
    }

    @IsTest
    static void testUpsertAndGetDiscounts() {
        Product2 testProd = TestDataFactory.createDefaultProduct();
        insert testProd;

        Discount__c d = TestDataFactory.createDefaultDiscount();
        d.Active__c = false;
        d.Target_Type__c = Util.DISCOUNT.TARGET.PRODUCTS;
        
        Test.startTest();
        DiscountManagerController.upsertDiscount(d, new List<Id>{testProd.Id});
        Test.stopTest();
        
        List<Discount__c> discounts = DiscountManagerController.getDiscounts();
        Assert.areEqual(1, discounts.size());
    }

    @IsTest
    static void testToggleDiscounts() {
        Discount__c discount = TestDataFactory.createDefaultDiscount();
        discount.Active__c = false;
        insert discount;

        Test.startTest();
        DiscountManagerController.toggleDiscounts(new List<Id>{discount.Id}, true);
        Test.stopTest();

        Assert.isTrue([SELECT Active__c FROM Discount__c WHERE Id = :discount.Id].Active__c);
    }

    @IsTest
    static void testCalculateOrderDiscounts() {
        insert TestDataFactory.createDefaultDiscountSetting();
        Product2 testProd = TestDataFactory.createDefaultProduct();
        insert testProd;

        Discount__c discount = TestDataFactory.createDefaultDiscount();
        discount.Target_Type__c = Util.DISCOUNT.TARGET.PRODUCTS;
        insert discount;

        insert TestDataFactory.createDiscountProduct(discount.Id, testProd.Id);

        String cartPayload = TestDataFactory.createCartPayload('01u000000000000', testProd.Id, Util.TEST.PRODUCT.DEFAULT_FAMILY, 100.0, 1);
        
        Test.startTest();
        Map<String, Object> calcResult = DiscountManagerController.calculateOrderDiscounts(cartPayload);
        Test.stopTest();
        
        Assert.isNotNull(calcResult);
        Assert.areEqual(10.0, calcResult.get('discountAmount'));
    }

    @IsTest
    static void testGetDiscountProducts() {
        Product2 testProd = TestDataFactory.createDefaultProduct();
        insert testProd;

        Discount__c discount = TestDataFactory.createDefaultDiscount();
        insert discount;

        insert TestDataFactory.createDiscountProduct(discount.Id, testProd.Id);

        Test.startTest();
        List<Id> fetchedProductIds = DiscountManagerController.getDiscountProducts(discount.Id);
        Test.stopTest();

        Assert.areEqual(1, fetchedProductIds.size());
        Assert.areEqual(testProd.Id, fetchedProductIds[0]);
    }

    @IsTest
    static void testDeleteDiscounts() {
        Discount__c discount = TestDataFactory.createDefaultDiscount();
        insert discount;

        Test.startTest();
        DiscountManagerController.deleteDiscounts(new List<Id>{discount.Id});
        Test.stopTest();

        Assert.areEqual(0, [SELECT Count() FROM Discount__c]);
    }
    
    @IsTest
    static void testUpsertExceptions() {
        Discount__c discountTooHigh = TestDataFactory.createDefaultDiscount();
        discountTooHigh.Value__c = 110.0;
        
        try {
            DiscountManagerController.upsertDiscount(discountTooHigh, null);
            Assert.isTrue(false);
        } catch (Exception e) {
            Assert.isTrue(true);
        }

        Discount__c discountMissingDate = TestDataFactory.createDefaultDiscount();
        discountMissingDate.Discount_Category__c = Util.DISCOUNT.CATEGORY.RECURRING;
        discountMissingDate.Recurrence__c = Util.DISCOUNT.RECURRENCE.YEARLY_CUSTOM;
        
        try {
            DiscountManagerController.upsertDiscount(discountMissingDate, null);
            Assert.isTrue(false);
        } catch (Exception e) {
            Assert.isTrue(true);
        }
    }

    @IsTest
    static void testDataRetrieval() {
        Test.startTest();
        List<Map<String, String>> families = DiscountManagerController.getAvailableFamilies();
        List<Product2> products = DiscountManagerController.getAvailableProducts();
        Test.stopTest();

        Assert.isNotNull(families);
        Assert.isNotNull(products);
    }
}