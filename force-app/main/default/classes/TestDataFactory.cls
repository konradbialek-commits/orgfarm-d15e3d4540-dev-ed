@IsTest
public class TestDataFactory {
    
    public static Product2 createDefaultProduct() {
        return createProduct(Util.TEST.PRODUCT.DEFAULT_NAME, Util.TEST.PRODUCT.DEFAULT_EXTERNAL_ID, false);
    }
    
    public static Product2 createProduct(String name, String externalId, Boolean isExternal) {
        return new Product2(
            Name = name,
            External_Product_Id__c = externalId,
            Is_External__c = isExternal,
            ProductCode = Util.TEST.PRODUCT.DEFAULT_CODE,
            Family = Util.TEST.PRODUCT.DEFAULT_FAMILY,
            IsActive = true
        );
    }

    public static Product_Sync_Queue__c createDefaultQueueItem(Id productId) {
        return createQueueItem(
            productId, 
            Util.PRODUCT_SYNC_QUEUE.OPERATION.INSERT_OPERATION, 
            Util.PRODUCT_SYNC_QUEUE.STATUS.PENDING, 
            '{}'
        );
    }

    public static Product_Sync_Queue__c createQueueItem(Id productId, String operation, String status, String payload) {
        return new Product_Sync_Queue__c(
            Product__c = productId,
            Operation__c = operation,
            Status__c = status,
            Payload__c = payload,
            Attempt_Count__c = 0
        );
    }

    public static String createProductPayloadJson(Product2 product) {
        String extId = String.isNotBlank(product.External_Product_Id__c) ? product.External_Product_Id__c : product.Id;
        ProductPayload payload = new ProductPayload(product, extId);
        return JSON.serialize(payload);
    }

    public static Discount_Setting__c createDefaultDiscountSetting() {
        return createDiscountSetting(
            Util.SETTINGS.DEFAULT_NAME, 
            Util.SETTINGS.STRATEGY.CUMULATIVE, 
            0.0
        );
    }

    public static Discount_Setting__c createDiscountSetting(String name, String strategy, Decimal minPriceFloor) {
        return new Discount_Setting__c(
            Name = name,
            Strategy__c = strategy,
            Minimum_Price_Floor_Percent__c = minPriceFloor
        );
    }

    public static Discount__c createDefaultDiscount() {
        return createDiscount(
            Util.TEST.DISCOUNT.DEFAULT_NAME, 
            true, 
            Util.DISCOUNT.CATEGORY.ONETIME, 
            Util.DISCOUNT.DISCOUNT_TYPE.PERCENT_VAL, 
            Util.TEST.DISCOUNT.DEFAULT_VALUE, 
            Util.DISCOUNT.TARGET.ALL_PRODUCTS
        );
    }

    public static Discount__c createDiscount(String name, Boolean isActive, String category, String type, Decimal value, String targetType) {
        return new Discount__c(
            Name = name,
            Active__c = isActive,
            Discount_Category__c = category,
            Discount_Type__c = type,
            Value__c = value,
            Target_Type__c = targetType
        );
    }

    public static Discount_Product__c createDiscountProduct(Id discountId, Id productId) {
        return new Discount_Product__c(
            Discount__c = discountId,
            Product__c = productId
        );
    }

    public static String createCartPayload(Id pbeId, Id pId, String family, Decimal unitPrice, Integer qty) {
        List<Map<String, Object>> payload = new List<Map<String, Object>>{
            new Map<String, Object>{
                'pricebookEntryId' => pbeId,
                'productId' => pId,
                'family' => family,
                'unitPrice' => unitPrice,
                'quantity' => qty
            }
        };
        return JSON.serialize(payload);
    }

    public static Error_Log__c createDefaultErrorLog() {
        return createErrorLog(
            Util.TEST.ERROR_LOG.DEFAULT_LOG_LEVEL,
            Util.TEST.ERROR_LOG.DEFAULT_CLASS_NAME,
            Util.TEST.ERROR_LOG.DEFAULT_METHOD_NAME,
            Util.TEST.ERROR_LOG.DEFAULT_ERROR_MESSAGE,
            Util.TEST.ERROR_LOG.DEFAULT_STACK_TRACE
        );
    }

    public static Error_Log__c createErrorLog(String logLevel, String className, String methodName, String errorMessage, String stackTrace) {
        return new Error_Log__c(
            Log_Level__c = logLevel,
            Class_Name__c = className,
            Method_Name__c = methodName,
            Error_Message__c = errorMessage,
            Stack_Trace__c = stackTrace
        );
    }

    public static Error_Event__e createDefaultErrorEvent(SObject recordToLog) {
        return createErrorEvent(
            String.valueOf(recordToLog.getSObjectType()),
            JSON.serialize(recordToLog)
        );
    }

    public static Error_Event__e createErrorEvent(String sobjectType, String payload) {
        return new Error_Event__e(
            SObject_Type__c = sobjectType,
            Payload__c = payload
        );
    }

    public static Account createAccount(String name) {
        return new Account(Name = name);
    }

    public static Opportunity createOpportunity(String name, String stageName, Date closeDate, Id accountId) {
        return new Opportunity(
            Name = name,
            StageName = stageName,
            CloseDate = closeDate,
            AccountId = accountId
        );
    }

    public static PricebookEntry createPricebookEntry(Id pricebookId, Id productId, Decimal unitPrice) {
        return new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            UnitPrice = unitPrice,
            IsActive = true
        );
    }

    public static OrderContext createOrderContext(Decimal totalAmount, Decimal eligibleSubtotal, Integer eligibleQuantity, Date orderDate) {
        return new OrderContext(totalAmount, eligibleSubtotal, eligibleQuantity, orderDate);
    }
}