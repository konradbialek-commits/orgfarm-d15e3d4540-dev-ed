@RestResource(urlMapping='/v1/products/*')
global class ProductSyncEndpoint {
    
    @HttpPost
    global static void upsertProduct() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String body = req.requestBody.toString();

        ErrorLogger.logInfo(
            'INBOUND POST | URI: ' + req.requestURI + ' | Body: ' + body,
            'ProductSyncEndpoint',
            'upsertProduct'
        );

        try {
            ProductPayload payload = (ProductPayload) JSON.deserialize(body, ProductPayload.class);

            List<Product2> existing = [
                SELECT Id FROM Product2
                WHERE External_Product_Id__c = :payload.externalProductId
                AND Is_External__c = true
                LIMIT 1
            ];

            Product2 product = existing.isEmpty() ? new Product2() : existing[0];
            product.Name = payload.name;
            product.Description = payload.description;
            product.ProductCode = payload.productCode;
            product.Family = payload.family;
            product.Language__c = payload.language;
            product.Is_External__c = true;
            product.Is_Deleted__c = false;
            product.External_Product_Id__c = payload.externalProductId;
            product.External_Org_Id__c = payload.externalOrgId;
            product.Sync_Status__c = Util.PRODUCT.SYNC_STATUS.SUCCESS;

            upsert product;

            String responseBody = JSON.serialize(new Map<String, String>{
                'status' => 'success',
                'productId' => product.Id
            });

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(responseBody);

            ErrorLogger.logInfo(
                'INBOUND POST SUCCESS | Response: ' + responseBody,
                'ProductSyncEndpoint',
                'upsertProduct'
            );

        } catch (Exception e) {
            String errorBody = JSON.serialize(new Map<String, String>{
                'status' => 'error',
                'message' => e.getMessage()
            });

            res.statusCode = 500;
            res.responseBody = Blob.valueOf(errorBody);

            ErrorLogger.logException(e, 'ProductSyncEndpoint', 'upsertProduct');
        }
    }

    @HttpDelete
    global static void softDeleteProduct() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String externalProductId = req.requestURI.substring(
            req.requestURI.lastIndexOf('/') + 1
        );

        ErrorLogger.logInfo(
            'INBOUND DELETE | ExternalProductId: ' + externalProductId,
            'ProductSyncEndpoint',
            'softDeleteProduct'
        );

        try {
            List<Product2> products = [
                SELECT Id FROM Product2
                WHERE External_Product_Id__c = :externalProductId
                AND Is_External__c = true
                LIMIT 1
            ];

            if (!products.isEmpty()) {
                products[0].Is_Deleted__c = true;
                products[0].Sync_Status__c = Util.PRODUCT.SYNC_STATUS.SUCCESS;
                update products[0];
            }

            String responseBody = JSON.serialize(new Map<String, String>{
                'status' => 'success'
            });

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(responseBody);

            ErrorLogger.logInfo(
                'INBOUND DELETE SUCCESS | ExternalProductId: ' + externalProductId,
                'ProductSyncEndpoint',
                'softDeleteProduct'
            );

        } catch (Exception e) {
            String errorBody = JSON.serialize(new Map<String, String>{
                'status' => 'error',
                'message' => e.getMessage()
            });

            res.statusCode = 500;
            res.responseBody = Blob.valueOf(errorBody);

            ErrorLogger.logException(e, 'ProductSyncEndpoint', 'softDeleteProduct');
        }
    }

    global class ProductPayload {
        public String externalProductId;
        public String externalOrgId;
        public String name;
        public String description;
        public String productCode;
        public String family;
        public String language;
    }
}