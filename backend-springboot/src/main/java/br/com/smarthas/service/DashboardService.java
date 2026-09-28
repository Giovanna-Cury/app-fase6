package br.com.smarthas.service;

import br.com.smarthas.analytics.SensorAnalyticsGateway;
import br.com.smarthas.dto.DashboardSummary;
import br.com.smarthas.model.AlertSeverity;
import br.com.smarthas.model.SensorStatus;
import br.com.smarthas.repository.AlertRepository;
import br.com.smarthas.repository.SensorReadingRepository;
import br.com.smarthas.repository.SensorRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Service
public class DashboardService {

    private final SensorRepository sensorRepository;
    private final AlertRepository alertRepository;
    private final SensorReadingRepository readingRepository;
    private final SensorAnalyticsGateway analyticsGateway;

    public DashboardService(SensorRepository sensorRepository,
                            AlertRepository alertRepository,
                            SensorReadingRepository readingRepository,
                            SensorAnalyticsGateway analyticsGateway) {
        this.sensorRepository = sensorRepository;
        this.alertRepository = alertRepository;
        this.readingRepository = readingRepository;
        this.analyticsGateway = analyticsGateway;
    }

    @Transactional(readOnly = true)
    public DashboardSummary summary() {
        return new DashboardSummary(
                sensorRepository.count(),
                sensorRepository.countByStatus(SensorStatus.ONLINE),
                sensorRepository.countByStatus(SensorStatus.OFFLINE),
                alertRepository.countByResolvedFalse(),
                sensorRepository.countByStatus(SensorStatus.WARNING),
                alertRepository.countByResolvedFalseAndSeverity(AlertSeverity.CRITICAL),
                readingRepository.countByReadAtGreaterThanEqual(LocalDateTime.now().minusHours(24)),
                analyticsGateway.engine()
        );
    }
}
