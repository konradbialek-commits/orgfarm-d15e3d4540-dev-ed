public class DiscountUtil {
    public String TARGET_ALL { get { return 'All Products'; } }
    public String TARGET_FAMILIES { get { return 'Specific Families'; } }
    public String TARGET_PRODUCTS { get { return 'Specific Products'; } }

    public String CAT_ONETIME { get { return 'One Time Only'; } }
    public String CAT_RECURRING { get { return 'Recurring'; } }
    public String CAT_CONDITIONAL { get { return 'Conditional'; } }

    public String COND_MIN_ORDER { get { return 'Minimum Order Value'; } }
    public String COND_TWO_FOR_ONE { get { return 'Two For One'; } }
    public String COND_VOLUME { get { return 'Volume Tier'; } }

    public String TYPE_PERCENT { get { return 'Percent'; } }
    public String TYPE_FIXED { get { return 'Fixed Amount'; } }

    public String REC_YEARLY_CUSTOM { get { return 'Yearly Custom Date'; } }
    public String REC_FIRST_DAY_OF_MONTH { get { return 'First Day of Month'; } }
}