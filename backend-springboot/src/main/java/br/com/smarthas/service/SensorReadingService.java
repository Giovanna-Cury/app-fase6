package br.com.smarthas.service;

import br.com.smarthas.analytics.SensorAnalyticsGateway;
import br.com.smarthas.dto.ReadingRegistration;
import br.com.smarthas.dto.ReadingRequest;
import br.com.smarthas.dto.SensorIndicators;
import br.com.smarthas.dto.SensorReadingDto;
import br.com.smarthas.exception.NotFoundException;
import br.com.smarthas.repository.SensorReadingRepository;
import br.com.smarthas.repository.SensorRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Casos de uso de telemetria. O registro da leitura é o "evento de back-end"
 * que aciona PRC_REGISTRAR_LEITURA no Oracle (REST → Java → JDBC → PL/SQL).
 */
@Service
public class SensorReadingService {

    private static final Logger log = LoggerFactory.getLogger(SensorReadingService.class);
    private static final int MAX_HISTORY = 500;
    private static final int INDICATOR_WINDOW_HOURS = 24;

    private final SensorAnalyticsGateway analyticsGateway;
    private final SensorReadingRepository readingRepository;
    private final SensorRepository sensorRepository;

    public SensorReadingService(SensorAnalyticsGateway analyticsGateway,
                                SensorReadingRepository readingRepository,
                                SensorRepository sensorRepository) {
        this.analyticsGateway = analyticsGateway;
        this.readingRepository = readingRepository;
        this.sensorRepository = sensorRepository;
    }

    /**
     * Transação controlada pela aplicação: a procedure online não faz COMMIT,
     * então leitura, estado do sensor e alerta são confirmados juntos aqui.
     */
    @Transactional
    public ReadingRegistration register(Long sensorId, ReadingRequest request) {
        ReadingRegistration result = analyticsGateway.registerReading(sensorId, request.value(), request.measuredAt());
        if (result.alertId() != null) {
            log.info("Leitura {} do sensor {} classificada como {} -> alerta {}",
                    result.readingId(), sensorId, result.classification(), result.alertId());
        }
        return result;
    }

    @Transactional(readOnly = true)
    public List<SensorReadingDto> history(Long sensorId, int limit) {
        if (!sensorRepository.existsById(sensorId)) {
            throw new NotFoundException("Sensor não encontrado: " + sensorId);
        }
        int size = Math.clamp(limit, 1, MAX_HISTORY);
        return readingRepository.findBySensorIdOrderByReadAtDescIdDesc(sensorId, PageRequest.of(0, size)).stream()
                .map(SensorReadingDto::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public SensorIndicators indicators(Long sensorId) {
        return analyticsGateway.indicators(sensorId, INDICATOR_WINDOW_HOURS);
    }
}
