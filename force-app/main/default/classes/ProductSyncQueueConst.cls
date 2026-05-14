public class ProductSyncQueueConst {

    public Status STATUS { get { return new Status(); } }
    public Operation OPERATION { get { return new Operation(); } }
    public TargetOrg TARGET_ORG { get { return new TargetOrg(); } }
    public String ENDPOINT_URL { get { return 'callout:Szymon_Org_API/services/apexrest/v1/products/'; } }

    public class Status {
        public String PENDING { get { return 'Pending'; } }
        public String SUCCESS { get { return 'Success'; } }
        public String FAILED { get { return 'Failed'; } }
        public String IN_PROGRESS { get { return 'In Progress'; } }
    }

    public class Operation {
        public String INSERT_OPERATION { get { return 'INSERT'; } }
        public String UPDATE_OPERATION { get { return 'UPDATE'; } }
        public String DELETE_OPERATION { get { return 'DELETE'; } }
    }

    public class TargetOrg {
        public String SZYMON_ORG { get { return 'Szymon_Org'; } }
    }
}