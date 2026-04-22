global class LeadReplyHandler implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        try {
            List<Lead> matchingLeads = [SELECT Id FROM Lead WHERE Email = :email.fromAddress AND IsConverted = false LIMIT 1];
            
            if (!matchingLeads.isEmpty()) {
                Lead targetLead = matchingLeads[0];
                Task emailTask = new Task();
                emailTask.WhoId = targetLead.Id;
                emailTask.Subject = 'Email Reply: ' + email.subject;
                emailTask.Description = email.plainTextBody;
                emailTask.Status = 'Completed';
                emailTask.TaskSubtype = 'Email';
                emailTask.ActivityDate = Date.today();
                
                insert emailTask;
                Messaging.SingleEmailMessage forwardMsg = new Messaging.SingleEmailMessage();
                forwardMsg.setToAddresses(new String[] {'konrad.bialek@britenet.eu'});
                forwardMsg.setSubject('FWD: ' + email.subject);
                forwardMsg.setPlainTextBody('Reply from ' + email.fromAddress + ':\n\n' + email.plainTextBody);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { forwardMsg });
                System.debug('Successfully logged email reply to Lead: ' + targetLead.Id);
            } else {
                System.debug('No active Lead found for email: ' + email.fromAddress);
            }
            
            result.success = true;
            
        } catch (Exception e) {
            System.debug('Error processing inbound email: ' + e.getMessage());
            result.success = false;
        }
        
        return result;
    }
}