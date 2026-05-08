public class DiscountStrategyFactory {
    public static DiscountStrategy getStrategy(String strategyName) {
        if (strategyName == Util.SETTINGS.STRATEGY.HIGHEST) {
            return new HighestValueStrategy();
        } else if (strategyName == Util.SETTINGS.STRATEGY.LOWEST) {
            return new LowestValueStrategy();
        } else {
            return new CumulativeStrategy(); 
        }
    }
}