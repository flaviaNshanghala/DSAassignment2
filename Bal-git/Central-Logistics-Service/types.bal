type DeliveryRequest record {
    ShipmentType shipmentType;
    string pickupLocation;
    string deliveryLocation;
    string[] preferredTimeSlots;
    string firstName;
    string lastName;
    string contactNumber;
};

type DeliveryResponse record {
    Status status;
    string trackingId;
    string estimatedDeliveryTime;
};

public enum ShipmentType {
    Standard, Express, International
}

public enum Status {
    Pending, Onroute, Delivered
}