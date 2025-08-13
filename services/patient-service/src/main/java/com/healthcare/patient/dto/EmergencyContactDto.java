package com.healthcare.patient.dto;

import jakarta.validation.constraints.NotBlank;

public class EmergencyContactDto {
    @NotBlank
    private String name;
    @NotBlank
    private String relationship;
    @NotBlank
    private String phoneNumber;

    // Getters and Setters
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getRelationship() { return relationship; }
    public void setRelationship(String relationship) { this.relationship = relationship; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
}