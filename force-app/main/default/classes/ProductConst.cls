public class ProductConst {
    public SyncStatus SYNC_STATUS { get { return new SyncStatus(); } }

    public class SyncStatus {
        public String PENDING { get { return 'Pending'; } }
        public String SUCCESS { get { return 'Success'; } }
        public String FAILED { get { return 'Failed'; } }
    }
}