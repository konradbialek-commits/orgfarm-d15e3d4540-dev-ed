trigger CaseOrderProductTrigger on Case_Order_Product__c(after update) {
    new MetadataTriggerHandler().run();
}
