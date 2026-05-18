public class ProductSyncEmailService {
    public static void sendFailureNotifications(List<Product_Sync_Queue__c> failedItems, Map<Id, Product2> productsMap) {
        try {
            String templateSubject = Util.EMAIL.PRODUCT_SYNC_FAILURE.SUBJECT;
            String templateBody = Util.EMAIL.PRODUCT_SYNC_FAILURE.BODY;
            String templateHtml = Util.EMAIL.PRODUCT_SYNC_FAILURE.HTML_VALUE;
            String templateDevName = Util.EMAIL.PRODUCT_SYNC_FAILURE.DEVELOPER_NAME;

            for (EmailTemplate emailTemplate : [
                SELECT Subject, Body, HtmlValue
                FROM EmailTemplate
                WHERE DeveloperName = :templateDevName
                LIMIT 1
            ]) {
                if (String.isNotBlank(emailTemplate.Subject)) {
                    templateSubject = emailTemplate.Subject;
                }
                if (String.isNotBlank(emailTemplate.Body)) {
                    templateBody = emailTemplate.Body;
                }
                if (String.isNotBlank(emailTemplate.HtmlValue)) {
                    templateHtml = emailTemplate.HtmlValue;
                }
            }

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

            String plainBody = templateBody.replace('[USER_NAME]', firstName).replace('[FAILED_PRODUCTS_LIST]', plainProductList);
            String htmlBody = templateHtml.replace('[USER_NAME]', firstName).replace('[FAILED_PRODUCTS_LIST]', htmlProductList);

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
            email.setSubject(templateSubject);
            email.setPlainTextBody(plainBody);
            email.setHtmlBody(htmlBody);

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            ErrorLogger.logException(e, 'ProductSyncEmailService', 'sendFailureNotifications');
        }
    }
}
