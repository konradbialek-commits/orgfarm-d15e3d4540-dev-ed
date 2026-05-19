trigger CaseTrigger on Case(after update) {
    new MetadataTriggerHandler().run();
}
