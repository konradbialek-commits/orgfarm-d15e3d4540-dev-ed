public class DiscountEvaluatorFactory {
    public static DiscountEvaluator getEvaluator(String criteriaType) {
        Type evaluatorType = Type.forName(criteriaType.deleteWhitespace() + 'Evaluator');
        if (evaluatorType != null) {
            return (DiscountEvaluator) evaluatorType.newInstance();
        }
        return new DefaultEvaluator();
    }
}