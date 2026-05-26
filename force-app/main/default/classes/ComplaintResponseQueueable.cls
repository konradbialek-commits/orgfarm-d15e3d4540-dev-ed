public class ComplaintResponseQueueable implements Queueable, Database.AllowsCallouts {
    private List<String> payloads;

    public ComplaintResponseQueueable(List<String> payloads) {
        this.payloads = payloads;
    }

    public void execute(QueueableContext context) {
        Http httpAgent = new Http();
        List<String> remainingPayloads = new List<String>();

        Integer maxProcess = Math.min(this.payloads.size(), 100);

        for (Integer i = 0; i < maxProcess; i++) {
            String payloadData = this.payloads[i];
            HttpRequest request = new HttpRequest();
            request.setEndpoint(Util.COMPLAINT.ENDPOINT_COMPLAINT_RESPONSE);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            request.setBody(payloadData);

            try {
                ErrorLogger.logInfo('OUTBOUND RESPONSE REQUEST | Payload: ' + payloadData, 'ComplaintResponseQueueable', 'execute');

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

        for (Integer i = maxProcess; i < this.payloads.size(); i++) {
            remainingPayloads.add(this.payloads[i]);
        }

        if (!remainingPayloads.isEmpty() && !Test.isRunningTest()) {
            System.enqueueJob(new ComplaintResponseQueueable(remainingPayloads));
        }
    }
}
