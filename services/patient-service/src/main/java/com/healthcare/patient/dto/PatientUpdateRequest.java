package com.healthcare.patient.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Pattern;

public class PatientUpdateRequest {
    private String firstName;
    private String lastName;
    @Email
    private String email;
    @Pattern(regexp = "\\d{10}")
    private String phoneNumber;
    private AddressDto address;
    private EmergencyContactDto emergencyContact;
    private String status;

    // Getters and Setters
    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }
    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public AddressDto getAddress() { return address; }
    public void setAddress(AddressDto address) { this.address = address; }
    public EmergencyContactDto getEmergencyContact() { return emergencyContact; }
    public void setEmergencyContact(EmergencyContactDto emergencyContact) { this.emergencyContact = emergencyContact; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}