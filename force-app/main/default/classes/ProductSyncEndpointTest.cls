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
        String payloadJson = TestDataFactory.createProductPayloadJson('EXT-TEST-001', 'ORG-TEST-001', 'Test Product', 'TS-001', 'Other');
        setupRestContext('POST', '/services/apexrest/v1/products', payloadJson);

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
        List<Product2> insertedProducts = [SELECT Id, Name, Is_External__c FROM Product2 WHERE External_Product_Id__c = 'EXT-TEST-001'];
        Assert.areEqual(1, insertedProducts.size());
    }

    @IsTest
    static void testUpsertProductUpdateSuccess() {
        Product2 existingProduct = TestDataFactory.createProduct('Old Name', 'EXT-TEST-002', true);
        String payloadJson = TestDataFactory.createProductPayloadJson('EXT-TEST-002', 'ORG-TEST-001', 'Updated Name', 'TS-002', 'Other');
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
        Product2 testProduct = TestDataFactory.createProduct('To Be Deleted', 'EXT-003', true);
        setupRestContext('DELETE', '/services/apexrest/v1/products/EXT-003', null);

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