trigger ProductSyncQueueTrigger on Product_Sync_Queue__c (
    before insert, after insert,
    before update, after update,
    before delete, after delete,
    after undelete
) {
    MetadataTriggerHandler.run();
}