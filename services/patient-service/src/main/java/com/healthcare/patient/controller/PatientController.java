package com.healthcare.patient.controller;

import com.healthcare.patient.dto.PatientCreateRequest;
import com.healthcare.patient.dto.PatientResponse;
import com.healthcare.patient.dto.PatientUpdateRequest;
import com.healthcare.patient.service.PatientService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/patients")
@Tag(name = "Patient Management", description = "APIs for managing patient information")
public class PatientController {

    @Autowired
    private PatientService patientService;

    @Operation(summary = "Create a new patient")
    @PostMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('NURSE')")
    public ResponseEntity<PatientResponse> createPatient(@Valid @RequestBody PatientCreateRequest request) {
        PatientResponse response = patientService.createPatient(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @Operation(summary = "Get patient by ID")
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('DOCTOR') or hasRole('NURSE')")
    public ResponseEntity<PatientResponse> getPatient(@PathVariable Long id) {
        PatientResponse response = patientService.getPatient(id);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Get all patients with pagination")
    @GetMapping
    @PreAuthorize("hasRole('ADMIN') or hasRole('DOCTOR') or hasRole('NURSE')")
    public ResponseEntity<Page<PatientResponse>> getAllPatients(Pageable pageable) {
        Page<PatientResponse> response = patientService.getAllPatients(pageable);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Update patient information")
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN') or hasRole('NURSE')")
    public ResponseEntity<PatientResponse> updatePatient(
            @PathVariable Long id, 
            @Valid @RequestBody PatientUpdateRequest request) {
        PatientResponse response = patientService.updatePatient(id, request);
        return ResponseEntity.ok(response);
    }

    @Operation(summary = "Delete patient")
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Void> deletePatient(@PathVariable Long id) {
        patientService.deletePatient(id);
        return ResponseEntity.noContent().build();
    }

    @Operation(summary = "Search patients by criteria")
    @GetMapping("/search")
    @PreAuthorize("hasRole('ADMIN') or hasRole('DOCTOR') or hasRole('NURSE')")
    public ResponseEntity<Page<PatientResponse>> searchPatients(
            @RequestParam(required = false) String firstName,
            @RequestParam(required = false) String lastName,
            @RequestParam(required = false) String email,
            @RequestParam(required = false) String medicalRecordNumber,
            Pageable pageable) {
        Page<PatientResponse> response = patientService.searchPatients(
            firstName, lastName, email, medicalRecordNumber, pageable);
        return ResponseEntity.ok(response);
    }
}
