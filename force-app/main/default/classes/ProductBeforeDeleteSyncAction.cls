public class ProductBeforeDeleteSyncAction implements TriggerAction.BeforeDelete {
    public void beforeDelete(List<Product2> oldList) {
        for (Product2 prod : oldList) {
            prod.addError('Products cannot be hard deleted. Please check the "Is Deleted" box instead.');
        }
    }
}