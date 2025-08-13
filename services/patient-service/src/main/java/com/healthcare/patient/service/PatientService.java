package com.healthcare.patient.service;

import com.healthcare.patient.dto.*;
import com.healthcare.patient.entity.Address;
import com.healthcare.patient.entity.EmergencyContact;
import com.healthcare.patient.entity.Patient;
import com.healthcare.patient.repository.PatientRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class PatientService {
    private final PatientRepository patientRepository;

    @Autowired
    public PatientService(PatientRepository patientRepository) {
        this.patientRepository = patientRepository;
    }

    public PatientResponse createPatient(PatientCreateRequest request) {
        Patient patient = new Patient();
        patient.setFirstName(request.getFirstName());
        patient.setLastName(request.getLastName());
        patient.setDateOfBirth(request.getDateOfBirth());
        patient.setGender(request.getGender());
        patient.setEmail(request.getEmail());
        patient.setPhoneNumber(request.getPhoneNumber());
        patient.setAddress(convertToAddress(request.getAddress()));
        patient.setEmergencyContact(convertToEmergencyContact(request.getEmergencyContact()));
        patient.setMedicalHistory(request.getMedicalHistory());
        patient.setStatus(request.getStatus());
        patient.setCreatedAt(LocalDateTime.now());
        patient.setUpdatedAt(LocalDateTime.now());

        Patient savedPatient = patientRepository.save(patient);
        return convertToResponse(savedPatient);
    }

    public Optional<PatientResponse> getPatientById(String id) {
        return patientRepository.findById(id).map(this::convertToResponse);
    }

    public Page<PatientResponse> getAllPatients(Pageable pageable) {
        return patientRepository.findAll(pageable).map(this::convertToResponse);
    }

    public PatientResponse updatePatient(String id, PatientUpdateRequest request) {
        Optional<Patient> existingPatient = patientRepository.findById(id);
        if (existingPatient.isPresent()) {
            Patient patient = existingPatient.get();
            patient.setFirstName(request.getFirstName());
            patient.setLastName(request.getLastName());
            patient.setEmail(request.getEmail());
            patient.setPhoneNumber(request.getPhoneNumber());
            patient.setAddress(convertToAddress(request.getAddress()));
            patient.setEmergencyContact(convertToEmergencyContact(request.getEmergencyContact()));
            patient.setMedicalHistory(request.getMedicalHistory());
            patient.setStatus(request.getStatus());
            patient.setUpdatedAt(LocalDateTime.now());

            Patient updatedPatient = patientRepository.save(patient);
            return convertToResponse(updatedPatient);
        }
        throw new RuntimeException("Patient not found");
    }

    public void deletePatient(String id) {
        if (patientRepository.existsById(id)) {
            patientRepository.deleteById(id);
        } else {
            throw new RuntimeException("Patient not found");
        }
    }

    public Page<PatientResponse> searchPatients(String query, Pageable pageable) {
        // Implement MongoDB text search or custom query logic
        // Example: Search by firstName or lastName (requires text index in MongoDB)
        // For simplicity, return all patients (update with actual query logic as needed)
        return patientRepository.findAll(pageable).map(this::convertToResponse);
    }

    private PatientResponse convertToResponse(Patient patient) {
        PatientResponse response = new PatientResponse();
        response.setId(patient.getId());
        response.setFirstName(patient.getFirstName());
        response.setLastName(patient.getLastName());
        response.setDateOfBirth(patient.getDateOfBirth());
        response.setGender(patient.getGender());
        response.setEmail(patient.getEmail());
        response.setPhoneNumber(patient.getPhoneNumber());
        response.setAddress(convertToAddressDto(patient.getAddress()));
        response.setEmergencyContact(convertToEmergencyContactDto(patient.getEmergencyContact()));
        response.setMedicalHistory(patient.getMedicalHistory());
        response.setStatus(patient.getStatus());
        response.setCreatedAt(patient.getCreatedAt());
        response.setUpdatedAt(patient.getUpdatedAt());
        return response;
    }

    private Address convertToAddress(AddressDto dto) {
        if (dto == null) return null;
        Address address = new Address();
        address.setStreet(dto.getStreet());
        address.setCity(dto.getCity());
        address.setState(dto.getState());
        address.setPostalCode(dto.getPostalCode());
        address.setCountry(dto.getCountry());
        return address;
    }

    private AddressDto convertToAddressDto(Address address) {
        if (address == null) return null;
        AddressDto dto = new AddressDto();
        dto.setStreet(address.getStreet());
        dto.setCity(address.getCity());
        dto.setState(address.getState());
        dto.setPostalCode(address.getPostalCode());
        dto.setCountry(address.getCountry());
        return dto;
    }

    private EmergencyContact convertToEmergencyContact(EmergencyContactDto dto) {
        if (dto == null) return null;
        EmergencyContact contact = new EmergencyContact();
        contact.setName(dto.getName());
        contact.setRelationship(dto.getRelationship());
        contact.setPhoneNumber(dto.getPhoneNumber());
        return contact;
    }

    private EmergencyContactDto convertToEmergencyContactDto(EmergencyContact contact) {
        if (contact == null) return null;
        EmergencyContactDto dto = new EmergencyContactDto();
        dto.setName(contact.getName());
        dto.setRelationship(contact.getRelationship());
        dto.setPhoneNumber(contact.getPhoneNumber());
        return dto;
    }
}