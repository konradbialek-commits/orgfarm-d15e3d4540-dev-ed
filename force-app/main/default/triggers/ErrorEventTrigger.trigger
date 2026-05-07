trigger ErrorEventTrigger on Error_Event__e (after insert) {
    new MetadataTriggerHandler().run();
}