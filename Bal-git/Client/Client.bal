import ballerina/http;
import ballerinax/kafka;
import ballerina/log;
import ballerina/lang.value;

configurable string TOPIC_requests = "delivery-requests";
configurable int LISTENER_PORT = 9090;
configurable string LISTENING_TOPIC_responses = "delivery-requests";

public final kafka:Producer Client = check new (kafka:DEFAULT_URL);

kafka:ConsumerConfiguration consumerConfigs = {
    groupId: "processed-response",
    topics: [LISTENING_TOPIC_responses],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
};

listener kafka:Listener ears = new (kafka:DEFAULT_URL,consumerConfigs);

service kafka:Service on ears {
    remote function onConsumerRecord(kafka:Caller caller,kafka:BytesConsumerRecord[] records) returns error? {
        foreach kafka:BytesConsumerRecord 'record in records {
            string messageContent = check string:fromBytes('record.value);

            json content = check value:fromJsonString(messageContent);

            json jsonResponse = content.cloneReadOnly();

            DeliveryResponse newResponse = check jsonResponse.ensureType(DeliveryResponse);

            log:printInfo("we have successfully delivered your package"+newResponse.toString());
        }
        kafka:Error? commitResult = caller->'commit();

        if commitResult is error{
            log:printError("Error occurred while committing the offset for the customer", 'error = commitResult);
        }
    }
}

service / on new http:Listener(LISTENER_PORT) {
    resource function post DeliveryRequest(DeliveryRequest request) returns string|error? {
        check publishDelivery(request);
        return "Message sent to the Kafka topic " + TOPIC_requests + " successfully. By " + request.firstName +" "+ request.lastName + ", shipment " + request.shipmentType;
    }
}

function publishDelivery(DeliveryRequest request) returns error?{
    log:printInfo("Publishing delivery"+request.toString());

    check Client ->send({ topic: TOPIC_requests, value: request.toString().toBytes()});
}
