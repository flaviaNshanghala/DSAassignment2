FROM openjdk:11-jre-slim
WORKDIR /app
COPY target/express-delivery-service.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
