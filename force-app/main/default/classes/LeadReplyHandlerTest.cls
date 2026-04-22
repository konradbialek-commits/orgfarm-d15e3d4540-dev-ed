@isTest
private class LeadReplyHandlerTest {

    @testSetup
    static void setupTestData() {
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test.lead@example.com',
            Status = 'Open - Not Contacted'
        );
        insert testLead;
    }

    @isTest
    static void testHandleInboundEmail_MatchingLeadFound() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'Re: Request for Information';
        email.fromAddress = 'test.lead@example.com';
        email.plainTextBody = 'This is a test reply from the lead.';
        
        LeadReplyHandler handler = new LeadReplyHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'The email handler should return success = true.');
        
        Lead targetLead = [SELECT Id FROM Lead WHERE Email = 'test.lead@example.com' LIMIT 1];
        List<Task> createdTasks = [SELECT Id, Subject, Description, Status, TaskSubtype, WhoId FROM Task WHERE WhoId = :targetLead.Id];
        
        System.assertEquals(1, createdTasks.size(), 'Exactly one Task should be created.');
        System.assertEquals('Email Reply: Re: Request for Information', createdTasks[0].Subject, 'Task subject did not match expected value.');
        System.assertEquals('This is a test reply from the lead.', createdTasks[0].Description, 'Task description did not match email body.');
        System.assertEquals('Completed', createdTasks[0].Status, 'Task status should be Completed.');
        System.assertEquals('Email', createdTasks[0].TaskSubtype, 'Task Subtype should be Email.');
    }

    @isTest
    static void testHandleInboundEmail_NoMatchingLead() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email.subject = 'Random Inquiry';
        email.fromAddress = 'unknown.person@example.com';
        email.plainTextBody = 'This sender does not exist in Salesforce.';
        
        LeadReplyHandler handler = new LeadReplyHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(email, env);
        Test.stopTest();
        
        System.assertEquals(true, result.success, 'The email handler should return true even if no lead is found.');
        
        List<Task> allTasks = [SELECT Id FROM Task];
        System.assertEquals(0, allTasks.size(), 'No Tasks should be created if no matching lead is found.');
    }

    @isTest
    static void testHandleInboundEmail_ExceptionHandling() {
        LeadReplyHandler handler = new LeadReplyHandler();

        Test.startTest();
        Messaging.InboundEmailResult result = handler.handleInboundEmail(null, null);
        Test.stopTest();

        System.assertEquals(false, result.success, 'The handler should return false when an exception occurs.');
    }
}