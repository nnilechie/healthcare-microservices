package com.healthcare.patient.controller;

import com.healthcare.patient.dto.*;
import com.healthcare.patient.service.PatientService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/patients")
@Tag(name = "Patients", description = "Patient Management API")
public class PatientController {
    private final PatientService patientService;

    public PatientController(PatientService patientService) {
        this.patientService = patientService;
    }

    @PostMapping
    @Operation(summary = "Create a new patient")
    @PreAuthorize("hasAuthority('WRITE_PATIENT')")
    public ResponseEntity<PatientResponse> createPatient(@Valid @RequestBody PatientCreateRequest request) {
        return new ResponseEntity<>(patientService.createPatient(request), HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get patient by ID")
    @PreAuthorize("hasAuthority('READ_PATIENT')")
    public ResponseEntity<PatientResponse> getPatient(@PathVariable String id) {
        return patientService.getPatientById(id)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }

    @GetMapping
    @Operation(summary = "Get all patients")
    @PreAuthorize("hasAuthority('READ_PATIENT')")
    public ResponseEntity<Page<PatientResponse>> getAllPatients(Pageable pageable) {
        return ResponseEntity.ok(patientService.getAllPatients(pageable));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update patient")
    @PreAuthorize("hasAuthority('WRITE_PATIENT')")
    public ResponseEntity<PatientResponse> updatePatient(@PathVariable String id, @Valid @RequestBody PatientUpdateRequest request) {
        return ResponseEntity.ok(patientService.updatePatient(id, request));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete patient")
    @PreAuthorize("hasAuthority('DELETE_PATIENT')")
    public ResponseEntity<Void> deletePatient(@PathVariable String id) {
        patientService.deletePatient(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/search")
    @Operation(summary = "Search patients")
    @PreAuthorize("hasAuthority('READ_PATIENT')")
    public ResponseEntity<Page<PatientResponse>> searchPatients(@RequestParam String query, Pageable pageable) {
        return ResponseEntity.ok(patientService.searchPatients(query, pageable));
    }
}