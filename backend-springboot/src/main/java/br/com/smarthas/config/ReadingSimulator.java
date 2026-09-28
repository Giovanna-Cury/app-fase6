package br.com.smarthas.config;

import br.com.smarthas.dto.ReadingRegistration;
import br.com.smarthas.dto.ReadingRequest;
import br.com.smarthas.model.Sensor;
import br.com.smarthas.model.SensorStatus;
import br.com.smarthas.repository.SensorRepository;
import br.com.smarthas.service.SensorReadingService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

/**
 * Simulador de gateway IoT (opcional, {@code smarthas.simulator.enabled=true}).
 * A cada intervalo envia uma leitura para um sensor aleatório pelo mesmo caso
 * de uso da API — no perfil Oracle, isso aciona PRC_REGISTRAR_LEITURA como um
 * evento de back-end, sem interação do usuário.
 */
@Component
@ConditionalOnProperty(prefix = "smarthas.simulator", name = "enabled", havingValue = "true")
public class ReadingSimulator {

    private static final Logger log = LoggerFactory.getLogger(ReadingSimulator.class);
    private static final double SPIKE_PROBABILITY = 0.08;

    private final SensorRepository sensorRepository;
    private final SensorReadingService readingService;

    public ReadingSimulator(SensorRepository sensorRepository, SensorReadingService readingService) {
        this.sensorRepository = sensorRepository;
        this.readingService = readingService;
    }

    @Scheduled(fixedDelayString = "${smarthas.simulator.interval-ms:15000}",
            initialDelayString = "${smarthas.simulator.interval-ms:15000}")
    public void emitReading() {
        // Sensores OFFLINE continuam mudos, preservando o cenário do watchdog.
        List<Sensor> active = sensorRepository.findAll().stream()
                .filter(s -> s.getStatus() != SensorStatus.OFFLINE && s.getValue() != null)
                .toList();
        if (active.isEmpty()) {
            return;
        }
        ThreadLocalRandom random = ThreadLocalRandom.current();
        Sensor sensor = active.get(random.nextInt(active.size()));
        double value = random.nextDouble() < SPIKE_PROBABILITY && sensor.getCriticalThreshold() != null
                ? sensor.getCriticalThreshold() * (1 + random.nextDouble(0.15))
                : sensor.getValue() * (1 + random.nextGaussian() * 0.03);
        value = Math.round(Math.max(0, value) * 100.0) / 100.0;

        try {
            ReadingRegistration result = readingService.register(sensor.getId(), new ReadingRequest(value, null));
            log.info("[simulador] {} = {} -> {}", sensor.getName(), value, result.classification());
        } catch (RuntimeException ex) {
            log.warn("[simulador] falha ao registrar leitura de {}: {}", sensor.getName(), ex.getMessage());
        }
    }
}
