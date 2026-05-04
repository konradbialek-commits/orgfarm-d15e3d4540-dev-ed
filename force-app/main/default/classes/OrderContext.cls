public class OrderContext {
    public Decimal totalAmount;
    public Decimal eligibleSubtotal;
    public Integer eligibleQuantity;
    public Date orderDate;
    
    public OrderContext(Decimal totalAmount, Decimal eligibleSubtotal, Integer eligibleQuantity, Date orderDate) {
        this.totalAmount = totalAmount;
        this.eligibleSubtotal = eligibleSubtotal;
        this.eligibleQuantity = eligibleQuantity;
        this.orderDate = orderDate;
    }
}