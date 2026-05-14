public class TestConst {
    public ProductTest PRODUCT { get { return new ProductTest(); } }
    public DiscountTest DISCOUNT { get { return new DiscountTest(); } }
    public ErrorLogTest ERROR_LOG { get { return new ErrorLogTest(); } }
    public OrderTest ORDER { get { return new OrderTest(); } }

    public class ProductTest {
        public String DEFAULT_NAME { get { return 'Standard Product'; } }
        public String DEFAULT_EXTERNAL_ID { get { return 'EXT-STD-000'; } }
        public String DEFAULT_CODE { get { return 'STD-CODE'; } }
        public String DEFAULT_FAMILY { get { return 'Other'; } }
    }

    public class DiscountTest {
        public String DEFAULT_NAME { get { return 'Standard Discount'; } }
        public Decimal DEFAULT_VALUE { get { return 10.0; } }
    }

    public class ErrorLogTest {
        public String DEFAULT_CLASS_NAME { get { return 'TestClass'; } }
        public String DEFAULT_METHOD_NAME { get { return 'TestMethod'; } }
        public String DEFAULT_LOG_LEVEL { get { return 'ERROR'; } }
        public String DEFAULT_ERROR_MESSAGE { get { return 'Test exception message'; } }
        public String DEFAULT_STACK_TRACE { get { return 'Line 1\nLine 2'; } }
    }

    public class OrderTest {
        public String DEFAULT_ACCOUNT_NAME { get { return 'BookSmart Test Account'; } }
        public String DEFAULT_OPPORTUNITY_NAME { get { return 'Test Opp'; } }
        public String DEFAULT_STAGE { get { return 'Prospecting'; } }
    }
}