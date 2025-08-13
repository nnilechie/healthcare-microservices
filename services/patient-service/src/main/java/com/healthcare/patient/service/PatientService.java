package com.healthcare.patient.service;

import com.healthcare.patient.dto.*;
import com.healthcare.patient.entity.*;
import com.healthcare.patient.exception.ResourceNotFoundException;
import com.healthcare.patient.repository.PatientRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.kafka.core.KafkaTemplate;

@Service
public class PatientService {
    private final PatientRepository patientRepository;
    private final KafkaTemplate<String, Object> kafkaTemplate;

    public PatientService(PatientRepository patientRepository, KafkaTemplate<String, Object> kafkaTemplate) {
        this.patientRepository = patientRepository;
        this.kafkaTemplate = kafkaTemplate;
    }

    @Transactional
    public PatientResponse createPatient(PatientCreateRequest request) {
        Patient patient = toEntity(request);
        patient = patientRepository.save(patient);
        kafkaTemplate.send("patient.created", patient);
        return toResponse(patient);
    }

    @Transactional(readOnly = true)
    public PatientResponse getPatient(Long id) {
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id: " + id));
        return toResponse(patient);
    }

    @Transactional(readOnly = true)
    public Page<PatientResponse> getAllPatients(Pageable pageable) {
        return patientRepository.findAll(pageable).map(this::toResponse);
    }

    @Transactional
    public PatientResponse updatePatient(Long id, PatientUpdateRequest request) {
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Patient not found with id: " + id));
        updateEntity(patient, request);
        patient = patientRepository.save(patient);
        kafkaTemplate.send("patient.updated", patient);
        return toResponse(patient);
    }

    @Transactional
    public void deletePatient(Long id) {
        if (!patientRepository.existsById(id)) {
            throw new ResourceNotFoundException("Patient not found with id: " + id);
        }
        patientRepository.deleteById(id);
        kafkaTemplate.send("patient.deleted", id);
    }

    @Transactional(readOnly = true)
    public Page<PatientResponse> searchPatients(String query, Pageable pageable) {
        return patientRepository.findAll(pageable).map(this::toResponse);
    }

    private Patient toEntity(PatientCreateRequest request) {
        Patient patient = new Patient();
        patient.setFirstName(request.getFirstName());
        patient.setLastName(request.getLastName());
        patient.setDateOfBirth(request.getDateOfBirth());
        patient.setGender(request.getGender());
        patient.setEmail(request.getEmail());
        patient.setPhoneNumber(request.getPhoneNumber());
        patient.setMedicalRecordNumber(request.getMedicalRecordNumber());
        patient.setStatus(request.getStatus());
        Address address = new Address();
        AddressDto addressDto = request.getAddress();
        if (addressDto != null) {
            address.setStreet(addressDto.getStreet());
            address.setCity(addressDto.getCity());
            address.setState(addressDto.getState());
            address.setPostalCode(addressDto.getPostalCode());
            address.setCountry(addressDto.getCountry());
        }
        patient.setAddress(address);
        EmergencyContact emergencyContact = new EmergencyContact();
        EmergencyContactDto emergencyContactDto = request.getEmergencyContact();
        if (emergencyContactDto != null) {
            emergencyContact.setName(emergencyContactDto.getName());
            emergencyContact.setRelationship(emergencyContactDto.getRelationship());
            emergencyContact.setPhoneNumber(emergencyContactDto.getPhoneNumber());
        }
        patient.setEmergencyContact(emergencyContact);
        return patient;
    }

    private PatientResponse toResponse(Patient patient) {
        PatientResponse response = new PatientResponse();
        response.setId(patient.getId());
        response.setFirstName(patient.getFirstName());
        response.setLastName(patient.getLastName());
        response.setDateOfBirth(patient.getDateOfBirth());
        response.setGender(patient.getGender());
        response.setEmail(patient.getEmail());
        response.setPhoneNumber(patient.getPhoneNumber());
        response.setMedicalRecordNumber(patient.getMedicalRecordNumber());
        response.setStatus(patient.getStatus());
        response.setCreatedAt(patient.getCreatedAt());
        response.setUpdatedAt(patient.getUpdatedAt());
        AddressDto addressDto = new AddressDto();
        Address address = patient.getAddress();
        if (address != null) {
            addressDto.setStreet(address.getStreet());
            addressDto.setCity(address.getCity());
            addressDto.setState(address.getState());
            addressDto.setPostalCode(address.getPostalCode());
            addressDto.setCountry(address.getCountry());
        }
        response.setAddress(addressDto);
        EmergencyContactDto emergencyContactDto = new EmergencyContactDto();
        EmergencyContact emergencyContact = patient.getEmergencyContact();
        if (emergencyContact != null) {
            emergencyContactDto.setName(emergencyContact.getName());
            emergencyContactDto.setRelationship(emergencyContact.getRelationship());
            emergencyContactDto.setPhoneNumber(emergencyContact.getPhoneNumber());
        }
        response.setEmergencyContact(emergencyContactDto);
        return response;
    }

    private void updateEntity(Patient patient, PatientUpdateRequest request) {
        if (request.getFirstName() != null) patient.setFirstName(request.getFirstName());
        if (request.getLastName() != null) patient.setLastName(request.getLastName());
        if (request.getEmail() != null) patient.setEmail(request.getEmail());
        if (request.getPhoneNumber() != null) patient.setPhoneNumber(request.getPhoneNumber());
        if (request.getStatus() != null) patient.setStatus(request.getStatus());
        AddressDto addressDto = request.getAddress();
        if (addressDto != null) {
            Address address = patient.getAddress() != null ? patient.getAddress() : new Address();
            address.setStreet(addressDto.getStreet());
            address.setCity(addressDto.getCity());
            address.setState(addressDto.getState());
            address.setPostalCode(addressDto.getPostalCode());
            address.setCountry(addressDto.getCountry());
            patient.setAddress(address);
        }
        EmergencyContactDto emergencyContactDto = request.getEmergencyContact();
        if (emergencyContactDto != null) {
            EmergencyContact emergencyContact = patient.getEmergencyContact() != null ? patient.getEmergencyContact() : new EmergencyContact();
            emergencyContact.setName(emergencyContactDto.getName());
            emergencyContact.setRelationship(emergencyContactDto.getRelationship());
            emergencyContact.setPhoneNumber(emergencyContactDto.getPhoneNumber());
            patient.setEmergencyContact(emergencyContact);
        }
    }
}