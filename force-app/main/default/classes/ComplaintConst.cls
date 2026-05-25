public class ComplaintConst {
    public String ENDPOINT_EXTERNAL_COMPLAINT {
        get {
            return 'callout:Szymon_Org_API/services/data/v60.0/sobjects/External_Complaint__e';
        }
    }
    public String ENDPOINT_COMPLAINT_RESPONSE {
        get {
            return 'callout:Szymon_Org_API/services/data/v60.0/sobjects/External_Complaint_Response__e';
        }
    }

    public RefundStatus STATUS {
        get {
            return new RefundStatus();
        }
    }
    public RefundType TYPE {
        get {
            return new RefundType();
        }
    }
    public SubjectPattern SUBJECT {
        get {
            return new SubjectPattern();
        }
    }
    public ResponseStatus RESPONSE_STATUS {
        get {
            return new ResponseStatus();
        }
    }

    public class RefundStatus {
        public String PENDING {
            get {
                return 'Pending';
            }
        }

        public String REJECTED {
            get {
                return 'Rejected';
            }
        }

        public String APPROVED_FULL {
            get {
                return 'Approved Full Refund';
            }
        }

        public String APPROVED_PARTIAL {
            get {
                return 'Approved Partial Refund';
            }
        }
    }

    public class RefundType {
        public String FULL {
            get {
                return 'Full';
            }
        }
        public String PARTIAL {
            get {
                return 'Partial';
            }
        }
    }

    public class SubjectPattern {
        public String LOCAL_REFUND {
            get {
                return 'Refund Request: ';
            }
        }
        public String EXTERNAL_REFUND {
            get {
                return 'External Refund Request';
            }
        }
    }

    public class ResponseStatus {
        public String CREATED {
            get {
                return 'Created';
            }
        }
    }
}
