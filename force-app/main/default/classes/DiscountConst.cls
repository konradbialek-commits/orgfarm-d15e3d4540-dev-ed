public class DiscountConst {
    public TargetPattern TARGET { get { return new TargetPattern(); } }
    public CategoryPattern CATEGORY { get { return new CategoryPattern(); } }
    public ConditionPattern CONDITION { get { return new ConditionPattern(); } }
    public TypePattern DISCOUNT_TYPE { get { return new TypePattern(); } }
    public RecurrencePattern RECURRENCE { get { return new RecurrencePattern(); } }

    public class TargetPattern {
        public String ALL_PRODUCTS { get { return 'All Products'; } }
        public String FAMILIES { get { return 'Specific Families'; } }
        public String PRODUCTS { get { return 'Specific Products'; } }
    }

    public class CategoryPattern {
        public String ONETIME { get { return 'One Time Only'; } }
        public String RECURRING { get { return 'Recurring'; } }
        public String CONDITIONAL { get { return 'Conditional'; } }
    }

    public class ConditionPattern {
        public String MIN_ORDER { get { return 'Minimum Order Value'; } }
        public String TWO_FOR_ONE { get { return 'Two For One'; } }
        public String VOLUME { get { return 'Volume Tier'; } }
    }

    public class TypePattern {
        public String PERCENT_VAL { get { return 'Percent'; } }
        public String FIXED { get { return 'Fixed Amount'; } }
    }

    public class RecurrencePattern {
        public String YEARLY_CUSTOM { get { return 'Yearly Custom Date'; } }
        public String FIRST_DAY_OF_MONTH { get { return 'First Day of Month'; } }
    }
}