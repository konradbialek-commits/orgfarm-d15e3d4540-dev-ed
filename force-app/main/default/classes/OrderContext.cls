public class OrderContext {
    public Decimal subtotal;
    public Decimal eligibleSubtotal;
    public Integer eligibleQuantity;
    public Date currentDate;

    public OrderContext(Decimal subtotal, Decimal eligibleSubtotal, Integer eligibleQuantity, Date currentDate) {
        this.subtotal = subtotal;
        this.eligibleSubtotal = eligibleSubtotal;
        this.eligibleQuantity = eligibleQuantity;
        this.currentDate = currentDate;
    }
}