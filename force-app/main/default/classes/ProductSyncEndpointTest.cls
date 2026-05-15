@IsTest
private class ProductSyncEndpointTest {
    @TestSetup
    static void setupData() {
        Product2 existingProduct = TestDataFactory.createDefaultProduct();
        existingProduct.Is_External__c = true;
        insert existingProduct;
    }

    private static void setupRestContext(String httpMethod, String uri, String body) {
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();

        request.httpMethod = httpMethod;
        request.requestURI = uri;

        if (body != null) {
            request.requestBody = Blob.valueOf(body);
        }

        RestContext.request = request;
        RestContext.response = response;
    }

    @IsTest
    static void testUpsertProductInsertSuccess() {
        Product2 payloadProduct = TestDataFactory.createDefaultProduct();
        payloadProduct.Is_External__c = true;
        payloadProduct.External_Product_Id__c = 'NEW-EXT-ID-123';
        String payloadJson = TestDataFactory.createProductPayloadJson(payloadProduct);
        setupRestContext('POST', '/services/apexrest/v1/products', payloadJson);

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
        List<Product2> insertedProducts = [SELECT Id, Name, Is_External__c FROM Product2 WHERE External_Product_Id__c = 'NEW-EXT-ID-123'];
        Assert.areEqual(1, insertedProducts.size());
    }

    @IsTest
    static void testUpsertProductUpdateSuccess() {
        Product2 existingProduct = [SELECT Id, External_Product_Id__c FROM Product2 LIMIT 1];

        Product2 payloadProduct = TestDataFactory.createDefaultProduct();
        payloadProduct.Name = 'Updated Name';
        payloadProduct.Is_External__c = true;
        payloadProduct.External_Product_Id__c = existingProduct.External_Product_Id__c;
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
        Product2 existingProduct = [SELECT Id, External_Product_Id__c FROM Product2 LIMIT 1];

        setupRestContext('DELETE', '/services/apexrest/v1/products/' + existingProduct.External_Product_Id__c, null);

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode);
        Product2 deletedProduct = [SELECT Is_Deleted__c FROM Product2 WHERE Id = :existingProduct.Id];
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
