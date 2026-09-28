package br.com.smarthas.service;

import br.com.smarthas.analytics.SensorAnalyticsGateway;
import br.com.smarthas.dto.DailyReportDto;
import br.com.smarthas.dto.ExecutionLogDto;
import br.com.smarthas.dto.ResponsibleSummary;
import br.com.smarthas.dto.RoutineResult;
import br.com.smarthas.repository.DailyReportRepository;
import br.com.smarthas.repository.ExecutionLogRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Relatórios e rotinas batch. As rotinas NÃO abrem transação na aplicação:
 * as procedures batch controlam o próprio COMMIT (podem rodar também via
 * DBMS_SCHEDULER, sem a API).
 */
@Service
public class ReportService {

    private static final int MAX_LOGS = 200;

    private final SensorAnalyticsGateway analyticsGateway;
    private final DailyReportRepository reportRepository;
    private final ExecutionLogRepository logRepository;

    public ReportService(SensorAnalyticsGateway analyticsGateway,
                         DailyReportRepository reportRepository,
                         ExecutionLogRepository logRepository) {
        this.analyticsGateway = analyticsGateway;
        this.reportRepository = reportRepository;
        this.logRepository = logRepository;
    }

    public RoutineResult generateDailyReport(LocalDate referenceDate) {
        LocalDate day = referenceDate != null ? referenceDate : LocalDate.now();
        int processed = analyticsGateway.generateDailyReport(day);
        return new RoutineResult("PRC_GERAR_RELATORIO_DIARIO", processed, analyticsGateway.engine(), LocalDateTime.now());
    }

    public RoutineResult checkInactiveSensors(int toleranceMinutes) {
        int offline = analyticsGateway.markInactiveSensors(toleranceMinutes);
        return new RoutineResult("PRC_VERIFICAR_SENSORES_INATIVOS", offline, analyticsGateway.engine(), LocalDateTime.now());
    }

    @Transactional(readOnly = true)
    public List<DailyReportDto> dailyReport(LocalDate referenceDate) {
        LocalDate day = referenceDate != null ? referenceDate : LocalDate.now();
        return reportRepository.findByReferenceDateOrderBySensorIdAsc(day).stream()
                .map(DailyReportDto::from)
                .toList();
    }

    public List<ResponsibleSummary> summaryByResponsible(int windowHours) {
        return analyticsGateway.summaryByResponsible(windowHours);
    }

    @Transactional(readOnly = true)
    public List<ExecutionLogDto> executionLogs(int limit) {
        return logRepository.findAllByOrderByIdDesc(PageRequest.of(0, Math.clamp(limit, 1, MAX_LOGS))).stream()
                .map(ExecutionLogDto::from)
                .toList();
    }
}
