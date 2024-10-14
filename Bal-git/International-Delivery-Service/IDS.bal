import ballerinax/kafka;
import ballerina/lang.value;
import ballerina/log;
import ballerina/uuid;

configurable string LISTENING_TOPIC_requests_International = "delivery-requests_International";
configurable string PUBLISH_TOPIC_responses_International = "delivery-responses_International";


kafka:Producer postResponses_International = check new (kafka:DEFAULT_URL);

kafka:ConsumerConfiguration consumerConfigs = {
    groupId: "processed-requests_International",
    topics: [LISTENING_TOPIC_requests_International],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
};

listener kafka:Listener kafkaListener = new (kafka:DEFAULT_URL, consumerConfigs);

service kafka:Service on kafkaListener {
    remote function onConsumerRecord(kafka:Caller caller, kafka:BytesConsumerRecord[] records) returns error? {
        error? err = from DeliveryRequest 'request in check getDeliveryRequests(records) where 'request.shipmentType == "International" do {
            DeliveryResponse response = {trackingId: generateTrackingId(),estimatedDeliveryTime: "TBD", status: "Delivered"};
            log:printInfo("Sending successful order to " + PUBLISH_TOPIC_responses_International + " " + response.toString());
            check postResponses_International->send({ topic: PUBLISH_TOPIC_responses_International, value: response.toString().toBytes()});
        };
        if err is error {
            log:printError("Unknown error occured ", err);
        }
    }
}


// function for requests
function getDeliveryRequests(kafka:BytesConsumerRecord[] records) returns DeliveryRequest[]|error {
    DeliveryRequest[] requests = [];
    foreach kafka:BytesConsumerRecord 'record in records {
        string messageContent = check string:fromBytes('record.value);
        json jsonContent = check value:fromJsonString(messageContent);
        json jsonClone = jsonContent.cloneReadOnly();
        DeliveryRequest request = check jsonClone.ensureType(DeliveryRequest);
        requests.push(request);
    }
    return requests;
}

// Define the function to generate a unique tracking ID
function generateTrackingId() returns string {
    // Implement a unique ID generation logic here
    // For simplicity, let's use a random UUID
    string trackingId = uuid:createRandomUuid();
    return trackingId;
}
