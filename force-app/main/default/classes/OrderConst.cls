public class OrderConst {
    public StatusPattern STATUS { get { return new StatusPattern(); } }

    public class StatusPattern {
        public String DRAFT { get { return 'Draft'; } }
    }
}