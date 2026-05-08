public class ProductConst {
    public SyncStatusPattern SYNC_STATUS { get { return new SyncStatusPattern(); } }

    public class SyncStatusPattern {
        public String PENDING { get { return 'Pending'; } }
        public String SUCCESS { get { return 'Success'; } }
        public String FAILED { get { return 'Failed'; } }
    }
}