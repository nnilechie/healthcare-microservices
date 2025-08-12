package com.healthcare.patient.service;

import com.healthcare.patient.dto.PatientCreateRequest;
import com.healthcare.patient.dto.PatientResponse;
import com.healthcare.patient.dto.PatientUpdateRequest;
import com.healthcare.patient.entity.Patient;
import com.healthcare.patient.exception.PatientNotFoundException;
import com.healthcare.patient.repository.PatientRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@Transactional
public class PatientService {

    @Autowired
    private PatientRepository patientRepository;

    @Autowired
    private KafkaTemplate<String, Object> kafkaTemplate;

    @Autowired
    private PatientMapper patientMapper;

    public PatientResponse createPatient(PatientCreateRequest request) {
        Patient patient = patientMapper.toEntity(request);
        patient.setMedicalRecordNumber(generateMedicalRecordNumber());
        
        Patient savedPatient = patientRepository.save(patient);
        
        // Publish event
        kafkaTemplate.send("patient-created", savedPatient.getId(), savedPatient);
        
        return patientMapper.toResponse(savedPatient);
    }

    @Cacheable(value = "patients", key = "#id")
    @Transactional(readOnly = true)
    public PatientResponse getPatient(Long id) {
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new PatientNotFoundException("Patient not found with id: " + id));
        return patientMapper.toResponse(patient);
    }

    @Transactional(readOnly = true)
    public Page<PatientResponse> getAllPatients(Pageable pageable) {
        Page<Patient> patients = patientRepository.findAll(pageable);
        return patients.map(patientMapper::toResponse);
    }

    @CacheEvict(value = "patients", key = "#id")
    public PatientResponse updatePatient(Long id, PatientUpdateRequest request) {
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new PatientNotFoundException("Patient not found with id: " + id));
        
        patientMapper.updateEntity(patient, request);
        Patient updatedPatient = patientRepository.save(patient);
        
        // Publish event
        kafkaTemplate.send("patient-updated", updatedPatient.getId(), updatedPatient);
        
        return patientMapper.toResponse(updatedPatient);
    }

    @CacheEvict(value = "patients", key = "#id")
    public void deletePatient(Long id) {
        Patient patient = patientRepository.findById(id)
                .orElseThrow(() -> new PatientNotFoundException("Patient not found with id: " + id));
        
        patient.setStatus(Patient.PatientStatus.INACTIVE);
        patientRepository.save(patient);
        
        // Publish event
        kafkaTemplate.send("patient-deleted", id, id);
    }

    @Transactional(readOnly = true)
    public Page<PatientResponse> searchPatients(String firstName, String lastName, 
                                              String email, String medicalRecordNumber, 
                                              Pageable pageable) {
        Page<Patient> patients = patientRepository.findBySearchCriteria(
            firstName, lastName, email, medicalRecordNumber, pageable);
        return patients.map(patientMapper::toResponse);
    }

    private String generateMedicalRecordNumber() {
        return "MRN" + System.currentTimeMillis() + UUID.randomUUID().toString().substring(0, 8);
    }
}
