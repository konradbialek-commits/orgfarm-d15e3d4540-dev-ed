public class DiscountEvaluatorFactory {
    
    public static DiscountEvaluator getEvaluator(String criteria) {
        if (String.isBlank(criteria)) {
            return new DefaultEvaluator();
        }

        String className = criteria.replaceAll('\\s+', '') + 'Evaluator';
        Type evaluatorType = Type.forName(className);
        
        if (evaluatorType != null) {
            return (DiscountEvaluator) evaluatorType.newInstance();
        }
        
        return new DefaultEvaluator();
    }
}