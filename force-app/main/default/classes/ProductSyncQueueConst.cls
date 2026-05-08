public class ProductSyncQueueConst {

    public StatusPattern STATUS { get { return new StatusPattern(); } }
    public OperationPattern OPERATION { get { return new OperationPattern(); } }
    public TargetOrgPattern TARGET_ORG { get { return new TargetOrgPattern(); } }
    public String ENDPOINT_URL { get { return 'callout:Szymon_Org_API/services/apexrest/v1/products/'; } }

    public class StatusPattern {
        public String PENDING { get { return 'Pending'; } }
        public String SUCCESS { get { return 'Success'; } }
        public String FAILED { get { return 'Failed'; } }
        public String IN_PROGRESS { get { return 'In Progress'; } }
    }

    public class OperationPattern {
        public String INSERT_OPERATION { get { return 'INSERT'; } }
        public String UPDATE_OPERATION { get { return 'UPDATE'; } }
        public String DELETE_OPERATION { get { return 'DELETE'; } }
    }

    public class TargetOrgPattern {
        public String SZYMON_ORG { get { return 'Szymon_Org'; } }
    }
}