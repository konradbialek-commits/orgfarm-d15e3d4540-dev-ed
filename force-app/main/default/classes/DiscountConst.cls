public class DiscountConst {
    public Target TARGET { get { return new Target(); } }
    public Category CATEGORY { get { return new Category(); } }
    public Condition CONDITION { get { return new Condition(); } }
    public Type DISCOUNT_TYPE { get { return new Type(); } }
    public RecurrencePattern RECURRENCE { get { return new RecurrencePattern(); } }

    public class Target {
        public String ALL_PRODUCTS { get { return 'All Products'; } }
        public String FAMILIES { get { return 'Specific Families'; } }
        public String PRODUCTS { get { return 'Specific Products'; } }
    }

    public class Category {
        public String ONETIME { get { return 'One Time Only'; } }
        public String RECURRING { get { return 'Recurring'; } }
        public String CONDITIONAL { get { return 'Conditional'; } }
    }

    public class Condition {
        public String MIN_ORDER { get { return 'Minimum Order Value'; } }
        public String TWO_FOR_ONE { get { return 'Two For One'; } }
        public String VOLUME { get { return 'Volume Tier'; } }
    }

    public class Type {
        public String PERCENT_VAL { get { return 'Percent'; } }
        public String FIXED { get { return 'Fixed Amount'; } }
    }

    public class RecurrencePattern {
        public String YEARLY_CUSTOM { get { return 'Yearly Custom Date'; } }
        public String FIRST_DAY_OF_MONTH { get { return 'First Day of Month'; } }
        public String DAILY { get { return 'Daily'; } }
    }
}