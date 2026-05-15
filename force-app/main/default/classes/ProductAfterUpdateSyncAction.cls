public class ProductAfterUpdateSyncAction implements TriggerAction.AfterUpdate {
    public void afterUpdate(List<Product2> newList, List<Product2> oldList) {
        List<Product2> updatedProducts = new List<Product2>();
        List<Product2> softDeletedProducts = new List<Product2>();

        for (Integer i = 0; i < newList.size(); i++) {
            Product2 newProd = newList[i];
            Product2 oldProd = oldList[i];

            if (newProd.Is_Deleted__c && !oldProd.Is_Deleted__c) {
                softDeletedProducts.add(newProd);
            } else {
                updatedProducts.add(newProd);
            }
        }

        if (!updatedProducts.isEmpty()) {
            ProductSyncService.enqueueProducts(updatedProducts, Util.PRODUCT_SYNC_QUEUE.OPERATION.UPDATE_OPERATION);
        }

        if (!softDeletedProducts.isEmpty()) {
            ProductSyncService.enqueueProducts(softDeletedProducts, Util.PRODUCT_SYNC_QUEUE.OPERATION.DELETE_OPERATION);
        }
    }
}