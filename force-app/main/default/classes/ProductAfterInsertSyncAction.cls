public class ProductAfterInsertSyncAction implements TriggerAction.AfterInsert {
    public void afterInsert(List<Product2> newList) {
        ProductSyncService.enqueueProducts(newList, 'INSERT');
    }
}