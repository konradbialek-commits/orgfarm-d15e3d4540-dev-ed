public class Util {

    public static final DiscountConst Discount = new DiscountConst();
    public static final SettingsConst Settings = new SettingsConst();
    public static final OrderConst Order = new OrderConst();

    public class DiscountConst {
        public final String TARGET_ALL = 'All Products';
        public final String TARGET_FAMILIES = 'Specific Families';
        public final String TARGET_PRODUCTS = 'Specific Products';

        public final String CAT_ONETIME = 'One Time Only';
        public final String CAT_RECURRING = 'Recurring';
        public final String CAT_CONDITIONAL = 'Conditional';

        public final String COND_MIN_ORDER = 'Minimum Order Value';
        public final String COND_TWO_FOR_ONE = 'Two For One';
        public final String COND_VOLUME = 'Volume Tier';

        public final String TYPE_PERCENT = 'Percent';
        public final String TYPE_FIXED = 'Fixed Amount';

        public final String REC_YEARLY_CUSTOM = 'Yearly Custom Date';
        public final String REC_FIRST_DAY_OF_MONTH = 'First Day of Month';
    }

    public class SettingsConst {
        public final String STRATEGY_CUMULATIVE = 'Cumulative';
        public final String STRATEGY_HIGHEST = 'Highest';
        public final String STRATEGY_LOWEST = 'Lowest';
        public final String DEFAULT_NAME = 'Global';
    }

    public class OrderConst {
        public final String STATUS_DRAFT = 'Draft';
    }
}