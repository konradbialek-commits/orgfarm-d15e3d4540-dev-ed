public class DiscountStrategyFactory {
    public static DiscountStrategy getStrategy(String strategyName) {
        if (strategyName == Util.Settings.STRATEGY_HIGHEST) {
            return new HighestValueStrategy();
        } else if (strategyName == Util.Settings.STRATEGY_LOWEST) {
            return new LowestValueStrategy();
        } else {
            return new CumulativeStrategy(); 
        }
    }
}