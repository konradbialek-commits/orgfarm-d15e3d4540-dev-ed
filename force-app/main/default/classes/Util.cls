public class Util {
    public class Discount {
        // Target Types
        public static final String TARGET_ALL = 'All Products';
        public static final String TARGET_FAMILIES = 'Specific Families';
        public static final String TARGET_PRODUCTS = 'Specific Products';

        // Discount Categories
        public static final String CAT_ONETIME = 'One Time Only';
        public static final String CAT_RECURRING = 'Recurring';
        public static final String CAT_CONDITIONAL = 'Conditional';

        // Condition Types
        public static final String COND_MIN_ORDER = 'Minimum Order Value';
        public static final String COND_TWO_FOR_ONE = 'Two For One';

        // Discount Types
        public static final String TYPE_PERCENT = 'Percent';
        public static final String TYPE_FIXED = 'Fixed Amount';

        // Recurrences
        public static final String REC_YEARLY_CUSTOM = 'Yearly Custom Date';
    }

    public class Settings {
        public static final String STRATEGY_CUMULATIVE = 'Cumulative';
        public static final String STRATEGY_HIGHEST = 'Highest';
        public static final String STRATEGY_LOWEST = 'Lowest';
        public static final String DEFAULT_NAME = 'Global';
    }

    public class Order {
        public static final String STATUS_DRAFT = 'Draft';
    }
}