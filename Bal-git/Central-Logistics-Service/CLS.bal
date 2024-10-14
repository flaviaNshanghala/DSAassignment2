import ballerina/lang.value;
import ballerina/log;
import ballerinax/kafka;

configurable string LISTENING_TOPIC_requests = "delivery-requests";
configurable string PUBLISH_TOPIC_responses = "delivery-responses";

configurable string LISTENING_TOPIC_responses_Standard = "delivery-requests_Standard";
configurable string PUBLISH_TOPIC_requests_Standard = "delivery-responses_Standard";

configurable string LISTENING_TOPIC_responses_Express = "delivery-requests_Express";
configurable string PUBLISH_TOPIC_requests_Express = "delivery-responses_Express";

configurable string LISTENING_TOPIC_responses_International = "delivery-requests_International";
configurable string PUBLISH_TOPIC_requests_International = "delivery-responses_International";

kafka:Producer postResponses = check new (kafka:DEFAULT_URL);
kafka:Producer postRequests_Standard = check new (kafka:DEFAULT_URL);
kafka:Producer postRequests_Express = check new (kafka:DEFAULT_URL);
kafka:Producer postRequests_International = check new (kafka:DEFAULT_URL);

kafka:ConsumerConfiguration consumerConfig = {
    groupId: "processed-requests",
    topics: [LISTENING_TOPIC_requests],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
};

kafka:ConsumerConfiguration consumerConfig_Standard = {
    groupId: "processed-responses_Standard",
    topics: [LISTENING_TOPIC_responses_Standard],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
};

kafka:ConsumerConfiguration consumerConfig_Express = {
    groupId: "processed-responses_Express",
    topics: [LISTENING_TOPIC_responses_Express],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
};

kafka:ConsumerConfiguration consumerConfig_International = {
    groupId: "processed-responses_International",
    topics: [LISTENING_TOPIC_responses_International],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
};

listener kafka:Listener requestListener = new (kafka:DEFAULT_URL, consumerConfig);
listener kafka:Listener responseListener_Standard = new (kafka:DEFAULT_URL, consumerConfig_Standard);
listener kafka:Listener responseListener_Express = new (kafka:DEFAULT_URL, consumerConfig_Express);
listener kafka:Listener responseListener_International = new (kafka:DEFAULT_URL, consumerConfig_International);

//  sending out requests
service kafka:Service on requestListener {
    remote function onConsumerRecord(kafka:Caller caller, kafka:BytesConsumerRecord[] records) returns error? {
        error? err = from DeliveryRequest 'request in check getDeliveryRequests(records)
            where 'request.shipmentType == 'request.shipmentType
            do {
                if 'request.shipmentType == "Express" {
                    log:printInfo("Sending successful " + PUBLISH_TOPIC_requests_Express + " " + 'request.toString());
                    check postRequests_Express->send({topic: PUBLISH_TOPIC_requests_Express, value: 'request.toString().toBytes()});
                }
                else if 'request.shipmentType == "Standard" {
                    log:printInfo("Sending successful " + PUBLISH_TOPIC_requests_Standard + " " + 'request.toString());
                    check postRequests_Express->send({topic: PUBLISH_TOPIC_requests_Standard, value: 'request.toString().toBytes()});
                }
                else if 'request.shipmentType == "International" {
                    log:printInfo("Sending successful " + PUBLISH_TOPIC_requests_International + " " + 'request.toString());
                    check postRequests_Express->send({topic: PUBLISH_TOPIC_requests_International, value: 'request.toString().toBytes()});
                }
            };
        if err is error {
            log:printError("Unknown error occured", err);
        }
    }
}

//  sending out responses from Standard
service kafka:Service on responseListener_Standard {
    remote function onConsumerRecord(kafka:Caller caller,kafka:BytesConsumerRecord[] records) returns error? {
    error? err = from DeliveryResponse 'response in check getDeliveryResponses(records) where 'response.status == "Delivered" do{
        log:printInfo("Sending successful "+PUBLISH_TOPIC_responses+" "+'response.toString());
        check postResponses->send({topic:PUBLISH_TOPIC_responses,value:  'response.toString().toBytes()});
    };
    if err is error {
        log:printError("Unknown error occured",err);
    }
}
}

//  sending out responses from Express
service kafka:Service on responseListener_Express {
    remote function onConsumerRecord(kafka:Caller caller,kafka:BytesConsumerRecord[] records) returns error? {
    error? err = from DeliveryResponse 'response in check getDeliveryResponses(records) where 'response.status == "Delivered" do{
        log:printInfo("Sending successful "+PUBLISH_TOPIC_responses+" "+'response.toString());
        check postResponses->send({topic:PUBLISH_TOPIC_responses,value:  'response.toString().toBytes()});
    };
    if err is error {
        log:printError("Unknown error occured",err);
    }
}
}

//  sending out responses from International
service kafka:Service on responseListener_International {
    remote function onConsumerRecord(kafka:Caller caller,kafka:BytesConsumerRecord[] records) returns error? {
    error? err = from DeliveryResponse 'response in check getDeliveryResponses(records) where 'response.status == "Delivered" do{
        log:printInfo("Sending successful "+PUBLISH_TOPIC_responses+" "+'response.toString());
        check postResponses->send({topic:PUBLISH_TOPIC_responses,value: 'response.toString().toBytes()});
    };
    if err is error {
        log:printError("Unknown error occured",err);
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

