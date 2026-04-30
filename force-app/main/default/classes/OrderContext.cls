public class OrderContext {
    public Decimal subtotal;
    public Integer totalQuantity;
    public Date currentDate;

    public OrderContext(Decimal subtotal, Integer totalQuantity, Date currentDate) {
        this.subtotal = subtotal;
        this.totalQuantity = totalQuantity;
        this.currentDate = currentDate;
    }
}