public class SettingsConst {
    public StrategyPattern STRATEGY { get { return new StrategyPattern(); } }
    public String DEFAULT_NAME { get { return 'Global'; } }

    public class StrategyPattern {
        public String CUMULATIVE { get { return 'Cumulative'; } }
        public String HIGHEST { get { return 'Highest'; } }
        public String LOWEST { get { return 'Lowest'; } }
    }
}