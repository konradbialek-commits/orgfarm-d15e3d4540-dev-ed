trigger RefundSyncEventTrigger on Refund_Sync_Event__e(after insert) {
    new MetadataTriggerHandler().run();
}
