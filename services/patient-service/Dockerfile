FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/patient-service-1.0.0.jar app.jar
COPY src/main/resources/application.yml resources/application.yml
ENTRYPOINT ["java", "-jar", "app.jar", "--spring.config.location=classpath:/BOOT-INF/classes/application.yml,file:/app/resources/application.yml"]