public class ComplaintResponseQueueable implements Queueable, Database.AllowsCallouts {
    private List<String> payloads;

    public ComplaintResponseQueueable(List<String> payloads) {
        this.payloads = payloads;
    }

    public void execute(QueueableContext context) {
        Http httpAgent = new Http();
        for (String payloadData : payloads) {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Util.COMPLAINT.ENDPOINT_COMPLAINT_RESPONSE);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(payloadData);

            try {
                HttpResponse response = httpAgent.send(request);
                if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
                    ErrorLogger.logInfo('OUTBOUND RESPONSE SUCCESS | ' + response.getBody(), 'ComplaintResponseQueueable', 'execute');
                } else {
                    ErrorLogger.logWarning('OUTBOUND RESPONSE FAILED | ' + response.getBody(), 'ComplaintResponseQueueable', 'execute');
                }
            } catch (Exception calloutException) {
                ErrorLogger.logException(calloutException, 'ComplaintResponseQueueable', 'execute');
            }
        }
    }
}
