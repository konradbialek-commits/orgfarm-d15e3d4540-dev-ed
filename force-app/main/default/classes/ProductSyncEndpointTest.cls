@IsTest
private class ProductSyncEndpointTest {

    @IsTest
    static void testUpsertProductSuccess() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/products';
        req.httpMethod = 'POST';

        Map<String, String> payload = new Map<String, String>{
            'externalProductId' => 'EXT-001',
            'externalOrgId' => 'ORG-001',
            'name' => 'Test Product',
            'productCode' => 'ABC-123'
        };

        req.requestBody = Blob.valueOf(JSON.serialize(payload));
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.upsertProduct();
        Test.stopTest();

        if (res.statusCode == 500) {
            System.debug('ENDPOINT ERROR: ' + res.responseBody.toString());
        }
        Assert.areEqual(200, res.statusCode);
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
        Product2 p = new Product2(
            Name = 'To Be Deleted',
            External_Product_Id__c = 'EXT-002',
            Is_External__c = true
        );
        insert p;

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/products/EXT-002';
        req.httpMethod = 'DELETE';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Assert.areEqual(200, res.statusCode);
        Product2 deletedProduct = [SELECT Is_Deleted__c, Sync_Status__c FROM Product2 WHERE Id = :p.Id];
        Assert.isTrue(deletedProduct.Is_Deleted__c);
        Assert.areEqual('Success', deletedProduct.Sync_Status__c);
    }

    @IsTest
    static void testSoftDeleteProductException() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/v1/products/'; 
        req.httpMethod = 'DELETE';
        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        ProductSyncEndpoint.softDeleteProduct();
        Test.stopTest();

        Assert.areEqual(200, res.statusCode); 
    }
}