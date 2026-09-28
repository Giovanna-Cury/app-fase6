package br.com.smarthas.controller;

import br.com.smarthas.dto.AlertDto;
import br.com.smarthas.dto.AlertRequest;
import br.com.smarthas.service.AlertService;
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
@RequestMapping("/api/alerts")
@Tag(name = "Alertas", description = "CRUD de alertas de monitoramento")
@SecurityRequirement(name = "bearerAuth")
public class AlertController {

    private final AlertService alertService;

    public AlertController(AlertService alertService) {
        this.alertService = alertService;
    }

    @GetMapping
    @Operation(summary = "Lista todos os alertas")
    public List<AlertDto> findAll() {
        return alertService.findAll();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Retorna um alerta pelo id")
    public AlertDto findById(@PathVariable Long id) {
        return alertService.findById(id);
    }

    @PostMapping
    @Operation(summary = "Cria um alerta (autenticado)")
    public ResponseEntity<AlertDto> create(@Valid @RequestBody AlertRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(alertService.create(request));
    }

    @PutMapping("/{id}/resolve")
    @Operation(summary = "Marca um alerta como resolvido (autenticado)")
    public AlertDto resolve(@PathVariable Long id) {
        return alertService.resolve(id);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Remove um alerta (ADMIN)")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        alertService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
