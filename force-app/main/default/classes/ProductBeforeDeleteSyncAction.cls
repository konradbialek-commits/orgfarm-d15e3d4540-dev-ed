public class ProductBeforeDeleteSyncAction implements TriggerAction.BeforeDelete {
    public void beforeDelete(List<Product2> oldList) {
        ProductSyncService.enqueueProducts(oldList, Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION);
    }
}