
import ballerinax/kafka;
import order_processor.types;
import ballerina/lang.value;
import ballerina/log;

configurable string LISTENING_TOPIC = ?;
configurable string PUBLISH_TOPIC = ?;


kafka:Producer kafkaProducer = check new (kafka:DEFAULT_URL);

kafka:ConsumerConfiguration consumerConfigs = {
    groupId: "processing-consumer",
    topics: [LISTENING_TOPIC],
    offsetReset: kafka:OFFSET_RESET_EARLIEST,
    pollingInterval: 1
};

listener kafka:Listener kafkaListener = new (kafka:DEFAULT_URL, consumerConfigs);

service kafka:Service on kafkaListener {

   
    remote function onConsumerRecord(kafka:Caller caller, kafka:BytesConsumerRecord[] records) returns error? {

        error? err = from types:Order 'order in check getOrdersFromRecords(records) where 'order.status == types:SUCCESS do {
            log:printInfo("Sending successful order to " + PUBLISH_TOPIC + " " + 'order.toString());
            check kafkaProducer->send({ topic: PUBLISH_TOPIC, value: 'order.toString().toBytes()});
        };
        if err is error {
            log:printError("Unknown error occured ", err);
        }
    }
}


function getOrdersFromRecords(kafka:BytesConsumerRecord[] records) returns types:Order[]|error {
    types:Order[] receivedOrders = [];
    foreach kafka:BytesConsumerRecord 'record in records {
        string messageContent = check string:fromBytes('record.value);
        json jsonContent = check value:fromJsonString(messageContent);
        json jsonClone = jsonContent.cloneReadOnly();
        types:Order receivedOrder = check jsonClone.ensureType(types:Order);
        receivedOrders.push(receivedOrder);
    }
    return receivedOrders;
}
