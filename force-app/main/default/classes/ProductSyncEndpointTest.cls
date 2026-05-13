@IsTest
private class ProductSyncEndpointTest {

    @IsTest
    static void testUpsertProductInsertSuccess() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/products';
        req.httpMethod = 'POST';

        Map<String, String> payload = new Map<String, String>{
            'externalProductId' => 'EXT-TEST-001',
            'externalOrgId' => 'ORG-TEST-001',
            'name' => 'Test Product',
            'productCode' => 'TS-001',
            'family' => 'Other'
        };

        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(200, res.statusCode);
        List<Product2> insertedProducts = [SELECT Id, Name, Is_External__c FROM Product2 WHERE External_Product_Id__c = 'EXT-TEST-001'];
        Assert.areEqual(1, insertedProducts.size());
    }

    @IsTest
    static void testUpsertProductUpdateSuccess() {
        Product2 existingP = TestDataFactory.createProduct(true, 'Old Name', 'EXT-TEST-002', true);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/products';
        req.httpMethod = 'POST';

        Map<String, String> payload = new Map<String, String>{
            'externalProductId' => 'EXT-TEST-002',
            'externalOrgId' => 'ORG-TEST-001',
            'name' => 'Updated Name',
            'productCode' => 'TS-002',
            'family' => 'Other'
        };

        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(200, res.statusCode);
        Product2 updatedProduct = [SELECT Name FROM Product2 WHERE Id = :existingP.Id];
        Assert.areEqual('Updated Name', updatedProduct.Name);
    }

    @IsTest
    static void testUpsertProductException() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/products';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"invalid_json":');
        
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        Assert.areEqual(500, res.statusCode);
    }

    @IsTest
    static void testSoftDeleteProductSuccess() {
        Product2 p = TestDataFactory.createProduct(true, 'To Be Deleted', 'EXT-003', true);

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/products/EXT-003';
        req.httpMethod = 'DELETE';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Assert.areEqual(200, res.statusCode);
        Product2 deletedProduct = [SELECT Is_Deleted__c FROM Product2 WHERE Id = :p.Id];
        Assert.isTrue(deletedProduct.Is_Deleted__c);
    }

    @IsTest
    static void testSoftDeleteProductException() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.httpMethod = 'DELETE';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Assert.areEqual(500, res.statusCode);
    }
}