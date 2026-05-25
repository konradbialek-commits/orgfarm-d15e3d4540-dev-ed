public class NotificationUtil {
    public static void sendStatusNotifications(List<Case> updatedCases) {
        CustomNotificationType notificationType = [
            SELECT Id
            FROM CustomNotificationType
            WHERE DeveloperName = 'External_Refund_Update'
            LIMIT 1
        ];

        for (Case updatedCase : updatedCases) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();

            notification.setTitle('External Refund ' + updatedCase.Refund_Status__c);
            notification.setBody(
                'The external refund request for Case ' + updatedCase.CaseNumber + ' has been ' + updatedCase.Refund_Status__c + '.'
            );
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(updatedCase.Id);

            try {
                notification.send(new Set<String>{ updatedCase.OwnerId });
            } catch (Exception e) {
                ErrorLogger.logException(e, 'NotificationUtil', 'sendStatusNotifications');
            }
        }
    }
}
