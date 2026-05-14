@IsTest
private class ProductSyncEndpointTest {

    private static void setupRestContext(String httpMethod, String uri, String body) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        req.httpMethod = httpMethod;
        req.requestURI = uri;
        
        if (body != null) {
            req.requestBody = Blob.valueOf(body);
        }
        
        RestContext.request = req;
        RestContext.response = res;
    }

    @IsTest
    static void testUpsertProductInsertSuccess() {
        Product2 payloadProduct = TestDataFactory.createDefaultProduct();
        payloadProduct.Is_External__c = true;
        String payloadJson = TestDataFactory.createProductPayloadJson(payloadProduct);
        setupRestContext('POST', '/services/apexrest/v1/products', payloadJson);

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
        List<Product2> insertedProducts = [SELECT Id, Name, Is_External__c FROM Product2 WHERE External_Product_Id__c = :Util.TEST.PRODUCT.DEFAULT_EXTERNAL_ID];
        Assert.areEqual(1, insertedProducts.size());
    }

    @IsTest
    static void testUpsertProductUpdateSuccess() {
        Product2 existingProduct = TestDataFactory.createDefaultProduct();
        existingProduct.Is_External__c = true;
        insert existingProduct;
        
        Product2 payloadProduct = TestDataFactory.createDefaultProduct();
        payloadProduct.Name = 'Updated Name';
        payloadProduct.Is_External__c = true;
        String payloadJson = TestDataFactory.createProductPayloadJson(payloadProduct);
        setupRestContext('POST', '/services/apexrest/v1/products', payloadJson);

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
        Product2 updatedProduct = [SELECT Name FROM Product2 WHERE Id = :existingProduct.Id];
        Assert.areEqual('Updated Name', updatedProduct.Name);
    }

    @IsTest
    static void testUpsertProductException() {
        setupRestContext('POST', '/services/apexrest/v1/products', '{"invalid_json":');

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(500, RestContext.response.statusCode);
    }

    @IsTest
    static void testSoftDeleteProductSuccess() {
        Product2 testProduct = TestDataFactory.createDefaultProduct();
        testProduct.Is_External__c = true;
        insert testProduct;
        
        setupRestContext('DELETE', '/services/apexrest/v1/products/' + Util.TEST.PRODUCT.DEFAULT_EXTERNAL_ID, null);

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
        Product2 deletedProduct = [SELECT Is_Deleted__c FROM Product2 WHERE Id = :testProduct.Id];
        Assert.isTrue(deletedProduct.Is_Deleted__c);
    }

    @IsTest
    static void testSoftDeleteProductException() {
        setupRestContext('DELETE', null, null);

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Assert.areEqual(500, RestContext.response.statusCode);
    }
}