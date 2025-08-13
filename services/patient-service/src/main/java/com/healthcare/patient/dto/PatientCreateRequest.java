package com.healthcare.patient.dto;

import jakarta.validation.constraints.*;
import java.time.LocalDate;

public class PatientCreateRequest {
    @NotBlank
    private String firstName;

    @NotBlank
    private String lastName;

    @Past
    private LocalDate dateOfBirth;

    @NotBlank
    private String gender;

    @Email
    private String email;

    @Pattern(regexp = "\\d{10}")
    private String phoneNumber;

    private AddressDto address;

    private EmergencyContactDto emergencyContact;

    @NotBlank
    private String medicalRecordNumber;

    @NotBlank
    private String status;

    // Getters and Setters
    public String getFirstName() { return firstName; }
    public void setFirstName(String firstName) { this.firstName = firstName; }
    public String getLastName() { return lastName; }
    public void setLastName(String lastName) { this.lastName = lastName; }
    public LocalDate getDateOfBirth() { return dateOfBirth; }
    public void setDateOfBirth(LocalDate dateOfBirth) { this.dateOfBirth = dateOfBirth; }
    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }
    public AddressDto getAddress() { return address; }
    public void setAddress(AddressDto address) { this.address = address; }
    public EmergencyContactDto getEmergencyContact() { return emergencyContact; }
    public void setEmergencyContact(EmergencyContactDto emergencyContact) { this.emergencyContact = emergencyContact; }
    public String getMedicalRecordNumber() { return medicalRecordNumber; }
    public void setMedicalRecordNumber(String medicalRecordNumber) { this.medicalRecordNumber = medicalRecordNumber; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}