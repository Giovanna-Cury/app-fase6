package br.com.smarthas.controller;

import br.com.smarthas.dto.SensorDto;
import br.com.smarthas.dto.SensorRequest;
import br.com.smarthas.service.SensorService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/sensors")
@Tag(name = "Sensores", description = "CRUD de sensores de monitoramento")
@SecurityRequirement(name = "bearerAuth")
public class SensorController {

    private final SensorService sensorService;

    public SensorController(SensorService sensorService) {
        this.sensorService = sensorService;
    }

    @GetMapping
    @Operation(summary = "Lista todos os sensores")
    public List<SensorDto> findAll() {
        return sensorService.findAll();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Retorna um sensor pelo id")
    public SensorDto findById(@PathVariable Long id) {
        return sensorService.findById(id);
    }

    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Cria um sensor (ADMIN)")
    public ResponseEntity<SensorDto> create(@Valid @RequestBody SensorRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(sensorService.create(request));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Atualiza um sensor (ADMIN)")
    public SensorDto update(@PathVariable Long id, @Valid @RequestBody SensorRequest request) {
        return sensorService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Remove um sensor (ADMIN)")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        sensorService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
