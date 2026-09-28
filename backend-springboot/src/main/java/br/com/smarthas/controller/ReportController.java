package br.com.smarthas.controller;

import br.com.smarthas.dto.DailyReportDto;
import br.com.smarthas.dto.ExecutionLogDto;
import br.com.smarthas.dto.ResponsibleSummary;
import br.com.smarthas.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/reports")
@Tag(name = "Relatórios", description = "Consultas sobre os dados consolidados pelas rotinas PL/SQL")
@SecurityRequirement(name = "bearerAuth")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("/daily")
    @Operation(summary = "Relatório diário por sensor (tabela SHAS_RELATORIO_DIARIO)")
    public List<DailyReportDto> daily(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return reportService.dailyReport(date);
    }

    @GetMapping("/responsibles")
    @Operation(summary = "Resumo por usuário responsável (PRC_RESUMO_POR_RESPONSAVEL, SYS_REFCURSOR)")
    public List<ResponsibleSummary> responsibles(@RequestParam(defaultValue = "24") int hours) {
        return reportService.summaryByResponsible(hours);
    }

    @GetMapping("/logs")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Trilha de auditoria das rotinas (SHAS_LOG_EXECUCAO) - ADMIN")
    public List<ExecutionLogDto> logs(@RequestParam(defaultValue = "20") int limit) {
        return reportService.executionLogs(limit);
    }
}
