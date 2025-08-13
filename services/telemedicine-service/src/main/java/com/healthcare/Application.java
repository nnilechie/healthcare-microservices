package com.healthcare;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}

@RestController
class HealthController {
    @GetMapping("/actuator/health")
    public String health() {
        return "{\"status\":\"UP\",\"service\":\"telemedicine-service\"}";
    }
    
    @GetMapping("/actuator/ready")
    public String ready() {
        return "{\"status\":\"READY\",\"service\":\"telemedicine-service\"}";
    }
}
