public class ProductPayload {
    public String externalProductId;
    public String externalOrgId;
    public String name;
    public String description;
    public String productCode;
    public String family;
    public String language;

    public ProductPayload() {}

    public ProductPayload(Product2 prod, String extId) {
        this.externalProductId = extId;
        this.externalOrgId = UserInfo.getOrganizationId();
        this.name = prod.Name;
        this.description = prod.Description;
        this.productCode = prod.ProductCode;
        this.family = prod.Family;
    }
}