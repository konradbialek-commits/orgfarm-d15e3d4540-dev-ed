public class Util {
    private static final DiscountUtil discountInstance = new DiscountUtil();
    private static final SettingsUtil settingsInstance = new SettingsUtil();
    private static final OrderUtil orderInstance = new OrderUtil();

    public static DiscountUtil Discount { get { return discountInstance; } }
    public static SettingsUtil Settings { get { return settingsInstance; } }
    public static OrderUtil Order { get { return orderInstance; } }
}