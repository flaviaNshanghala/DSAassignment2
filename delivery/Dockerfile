FROM openjdk:11-jre-slim
WORKDIR /app
COPY target/central-logistics-service.jar app.jar
COPY target/standard-delivery-service.jar app.jar
COPY target/express-delivery-service.jar app.jar
COPY target/international-delivery-service.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
