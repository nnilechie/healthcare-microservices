FROM openjdk:17-jre-slim
WORKDIR /app
COPY target/billing-service-1.0.0.jar app.jar
EXPOSE 808$(echo $service | tail -c 2)
ENTRYPOINT ["java", "-jar", "app.jar"]
