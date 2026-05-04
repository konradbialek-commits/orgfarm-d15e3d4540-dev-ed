public class DiscountEvaluatorFactory {
    
    public static DiscountEvaluator getEvaluator(String criteria) {
        if (criteria == Util.Discount.COND_TWO_FOR_ONE) {
            return new TwoForOneEvaluator();
        } else if (criteria == Util.Discount.COND_MIN_ORDER) {
            return new MinimumOrderValueEvaluator();
        } else if (criteria == Util.Discount.COND_VOLUME) {
            return new VolumeTierEvaluator();
        } else if (criteria == 'First Day of Month') {
            return new FirstDayOfMonthEvaluator();
        } else if (criteria == Util.Discount.REC_YEARLY_CUSTOM) {
            return new YearlyCustomDateEvaluator();
        } else {
            return new DefaultEvaluator();
        }
    }
}