public class ProductAfterUpdateSyncAction implements TriggerAction.AfterUpdate {
    public void afterUpdate(List<Product2> newList, List<Product2> oldList) {
        ProductSyncService.enqueueProducts(newList, Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION);
    }
}