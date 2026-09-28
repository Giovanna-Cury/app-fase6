package br.com.smarthas.controller;

import br.com.smarthas.dto.RoutineResult;
import br.com.smarthas.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;

/** Dispara sob demanda as rotinas batch que também rodam agendadas no banco. */
@RestController
@RequestMapping("/api/routines")
@PreAuthorize("hasRole('ADMIN')")
@Tag(name = "Rotinas PL/SQL", description = "Execução das procedures batch (ADMIN)")
@SecurityRequirement(name = "bearerAuth")
public class RoutineController {

    private final ReportService reportService;

    public RoutineController(ReportService reportService) {
        this.reportService = reportService;
    }

    @PostMapping("/daily-report")
    @Operation(summary = "Gera o relatório diário (PRC_GERAR_RELATORIO_DIARIO)")
    public RoutineResult dailyReport(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return reportService.generateDailyReport(date);
    }

    @PostMapping("/inactive-sensors")
    @Operation(summary = "Marca sensores sem comunicação como OFFLINE (PRC_VERIFICAR_SENSORES_INATIVOS)")
    public RoutineResult inactiveSensors(@RequestParam(defaultValue = "60") int toleranceMinutes) {
        return reportService.checkInactiveSensors(toleranceMinutes);
    }
}
