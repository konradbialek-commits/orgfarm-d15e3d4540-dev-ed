trigger ExternalComplaintTrigger on External_Complaint__e(after insert) {
    new MetadataTriggerHandler().run();
}
