public class EmailConst {
    public ProductSyncFailure PRODUCT_SYNC_FAILURE {
        get {
            return new ProductSyncFailure();
        }
    }

    public class ProductSyncFailure {
        public String DEVELOPER_NAME {
            get {
                return 'Product_Sync_Failure_Template';
            }
        }
        public String SUBJECT {
            get {
                return 'ACTION REQUIRED: Product Synchronization Failures';
            }
        }
        public String BODY {
            get {
                return 'Hello [USER_NAME],\n\nThe synchronization for the following products has failed 3 times and will no longer be retried automatically.\n\n[FAILED_PRODUCTS_LIST]\n\nPlease review the data and update these products in Salesforce to re-trigger the sync.\n\nAutomated message from your Salesforce System';
            }
        }
        public String HTML_VALUE {
            get {
                return '<html><body><p>Hello <strong>[USER_NAME]</strong>,</p><p>The synchronization for the following products has failed 3 times and will no longer be retried automatically.</p><div style="background-color: #ffebee; border-left: 4px solid #d32f2f; padding: 15px; margin-bottom: 20px;">[FAILED_PRODUCTS_LIST]</div><p>Please review the data and update these products in Salesforce to re-trigger the sync.</p></body></html>';
            }
        }
    }
}
