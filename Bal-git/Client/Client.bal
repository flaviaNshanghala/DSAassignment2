import ballerina/http;
import ballerina/lang.value;
import ballerina/log;
import ballerina/sql;
import ballerinax/kafka;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

configurable string TOPIC_requests = "delivery-requests";
configurable int LISTENER_PORT = 9090;
configurable string LISTENING_TOPIC_responses = "delivery-requests";

configurable string host = ?;
configurable string username = ?;
configurable string password = ?;
configurable string databaseName = ?;

public final mysql:Client databaseClient = check new (host, username, password, databaseName, 3306);

public final kafka:Producer Client = check new (kafka:DEFAULT_URL);

kafka:ConsumerConfiguration consumerConfigs = {
    groupId: "processed-response",
    topics: [LISTENING_TOPIC_responses],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
};

listener kafka:Listener ears = new (kafka:DEFAULT_URL, consumerConfigs);

service kafka:Service on ears {

    remote function onConsumerRecord(kafka:Caller caller, kafka:BytesConsumerRecord[] records) returns error? {
        error? err = from DeliveryResponse 'response in check getDeliveryResponses(records)
            where 'response.status == "Delivered"
            do {
                sql:ExecutionResult result = check databaseClient->execute(insert into DeliveryResponse (status, trackingId, estimatedDeliveryTime, preferredTimeSlots) values (${'response.status},  ${'response.trackingId}, ${'response.estimatedDeliveryTime}));
                int|string? lastInsertId = result.lastInsertId;
        if lastInsertId is int {
            log:printInfo("Recieving successful "+LISTENING_TOPIC_responses+" "+'response.toString());
        } else {
            log:printError("Unable to obtain last insert ID");
        }
            };
        if err is error {
            log:printError("Unknown error occured", err);
        }
    }
}

service / on new http:Listener(LISTENER_PORT) {
    resource function post DeliveryRequest(DeliveryRequest request) returns string|error? {
        check publishDelivery(request);
        sql:ExecutionResult result = check databaseClient->execute(insert into DeliveryRequest (shipmentType, pickupLocation, deliveryLocation, preferredTimeSlots, firstName, lastName, contactNumber) values (${request.shipmentType}, ${request.pickupLocation},${request.deliveryLocation}, ${request.preferredTimeSlots}, ${request.firstName}, ${request.lastName}, ${request.contactNumber}));
        int|string? lastInsertId = result.lastInsertId;
        if lastInsertId is int {
            return "Message sent to the Kafka topic " + TOPIC_requests + " successfully. By " + request.firstName + " " + request.lastName + ", shipment " + request.shipmentType;
        } else {
            return error("Unable to obtain last insert ID");
        }
    }
}

function publishDelivery(DeliveryRequest request) returns error? {
    log:printInfo("Publishing delivery" + request.toString());

    check Client->send({topic: TOPIC_requests, value: request.toString().toBytes()});
}

// function for responses
function getDeliveryResponses(kafka:BytesConsumerRecord[] records) returns DeliveryResponse[]|error {
    DeliveryResponse[] responses = [];
    foreach kafka:BytesConsumerRecord 'record in records {
        string messageContent = check string:fromBytes('record.value);
        json jsonContent = check value:fromJsonString(messageContent);
        json jsonClone = jsonContent.cloneReadOnly();
        DeliveryResponse response = check jsonClone.ensureType(DeliveryResponse);
        responses.push(response);
    }
    return responses;
}
