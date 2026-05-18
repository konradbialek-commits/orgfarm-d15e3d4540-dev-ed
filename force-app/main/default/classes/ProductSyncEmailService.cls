public class ProductSyncEmailService {
    public static void sendFailureNotifications(List<Product_Sync_Queue__c> failedItems, Map<Id, Product2> productsMap) {
        try {
            EmailTemplate template = [
                SELECT Id, Subject, Body, HtmlValue
                FROM EmailTemplate
                WHERE DeveloperName = 'Product_Sync_Failure_Template'
                LIMIT 1
            ];

            String plainProductList = '';
            String htmlProductList = '<ul style="margin: 0; padding-left: 20px;">';

            for (Product_Sync_Queue__c item : failedItems) {
                Product2 prod = productsMap.get(item.Product__c);

                plainProductList += '• Product: ' + prod.Name + ' (' + prod.ProductCode + ')\n';
                plainProductList += '  Operation: ' + item.Operation__c + '\n';
                plainProductList += '  Error: ' + item.Error_Message__c + '\n\n';

                htmlProductList += '<li style="margin-bottom: 10px;">';
                htmlProductList += '<strong>Product:</strong> ' + prod.Name + ' (' + prod.ProductCode + ')<br/>';
                htmlProductList += '<strong>Operation:</strong> ' + item.Operation__c + '<br/>';
                htmlProductList += '<strong>Error:</strong> <span style="color: #d32f2f;">' + item.Error_Message__c + '</span>';
                htmlProductList += '</li>';
            }
            htmlProductList += '</ul>';

            String firstName = String.isNotBlank(UserInfo.getFirstName()) ? UserInfo.getFirstName() : 'Admin';

            String plainBody = template.Body != null
                ? template.Body.replace('[USER_NAME]', firstName).replace('[FAILED_PRODUCTS_LIST]', plainProductList)
                : '';

            String htmlBody = template.HtmlValue != null
                ? template.HtmlValue.replace('[USER_NAME]', firstName).replace('[FAILED_PRODUCTS_LIST]', htmlProductList)
                : '';

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
            email.setSubject(template.Subject);

            if (String.isNotBlank(plainBody)) {
                email.setPlainTextBody(plainBody);
            }
            if (String.isNotBlank(htmlBody)) {
                email.setHtmlBody(htmlBody);
            }

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            ErrorLogger.logException(e, 'ProductSyncEmailService', 'sendFailureNotifications');
        }
    }
}
