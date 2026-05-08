public class ProductAfterUpdateSyncAction implements TriggerAction.AfterUpdate {
    public void afterUpdate(List<Product2> newList, List<Product2> oldList) {
        ProductSyncService.enqueueProducts(newList, 'UPDATE');
    }
}