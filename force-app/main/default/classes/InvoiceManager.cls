public with sharing class InvoiceManager {

    @AuraEnabled(cacheable=true)
    public static Boolean isInvoiceSigned(String orderId) {
        List<Invoice__c> invoices = [SELECT Status__c FROM Invoice__c WHERE Order__c = :orderId LIMIT 1];
        if (!invoices.isEmpty() && invoices[0].Status__c == 'Signed') {
            return true;
        }
        return false;
    }

    @InvocableMethod(label='Generate Unsigned Invoice' description='Generates a PDF for Activated Orders')
    public static void generateInvoiceFromFlow(List<Id> invoiceIds) {
        List<Invoice__c> invoices = [SELECT Id, Order__c FROM Invoice__c WHERE Id IN :invoiceIds];
        for(Invoice__c inv : invoices) {
            generatePDF(inv.Id, inv.Order__c, null, 'Unsigned Invoice');
        }
    }

    @AuraEnabled
    public static String signAndRegenerateInvoice(String orderId, String base64Signature) {
        try {
            Invoice__c activeInvoice = [SELECT Id, Status__c FROM Invoice__c WHERE Order__c = :orderId LIMIT 1];

            if (activeInvoice.Status__c == 'Signed') {
                throw new AuraHandledException('This invoice has already been signed and cannot be altered.');
            }

            ContentVersion sigFile = new ContentVersion();
            sigFile.VersionData = EncodingUtil.base64Decode(base64Signature.split(',')[1]);
            sigFile.Title = 'Signature - ' + Datetime.now().format();
            sigFile.PathOnClient = 'Signature.png';
            sigFile.FirstPublishLocationId = orderId; 
            insert sigFile;

            activeInvoice.Status__c = 'Signed';
            update activeInvoice;

            generatePDF(activeInvoice.Id, orderId, sigFile.Id, 'Signed Invoice Final');
            return 'Success';
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    @future(callout=true) 
    private static void generatePDF(Id invoiceId, Id orderId, Id sigId, String documentTitle) {
        PageReference pdfPage = Page.OrderInvoicePDF;
        pdfPage.getParameters().put('id', invoiceId);
        if(sigId != null) { pdfPage.getParameters().put('sigId', sigId); }
        Blob pdfBlob;
        if(Test.isRunningTest()) { pdfBlob = Blob.valueOf('Test PDF'); } else { pdfBlob = pdfPage.getContentAsPDF(); }
        ContentVersion pdfFile = new ContentVersion();
        pdfFile.VersionData = pdfBlob;
        pdfFile.Title = documentTitle + ' - ' + Datetime.now().format();
        pdfFile.PathOnClient = 'Invoice.pdf';
        pdfFile.FirstPublishLocationId = orderId; 
        insert pdfFile;
    }
}