trigger ExternalComplaintResponseTrigger on External_Complaint_Response__e(after insert) {
    new MetadataTriggerHandler().run();
}
