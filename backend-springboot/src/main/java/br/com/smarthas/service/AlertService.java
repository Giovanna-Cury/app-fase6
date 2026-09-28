package br.com.smarthas.service;

import br.com.smarthas.dto.AlertDto;
import br.com.smarthas.dto.AlertRequest;
import br.com.smarthas.exception.NotFoundException;
import br.com.smarthas.model.Alert;
import br.com.smarthas.model.AlertOrigin;
import br.com.smarthas.repository.AlertRepository;
import br.com.smarthas.repository.SensorRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class AlertService {

    private final AlertRepository alertRepository;
    private final SensorRepository sensorRepository;

    public AlertService(AlertRepository alertRepository, SensorRepository sensorRepository) {
        this.alertRepository = alertRepository;
        this.sensorRepository = sensorRepository;
    }

    /** Mais recentes primeiro: é assim que o operador consome a fila de alertas. */
    @Transactional(readOnly = true)
    public List<AlertDto> findAll() {
        return alertRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(AlertDto::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public AlertDto findById(Long id) {
        return AlertDto.from(getEntity(id));
    }

    @Transactional
    public AlertDto create(AlertRequest request) {
        Alert alert = new Alert(
                request.title(),
                request.description(),
                request.severity(),
                request.location(),
                LocalDateTime.now(),
                false
        );
        alert.setOrigin(AlertOrigin.MANUAL);
        if (request.sensorId() != null) {
            alert.setSensor(sensorRepository.findById(request.sensorId())
                    .orElseThrow(() -> new NotFoundException("Sensor não encontrado: " + request.sensorId())));
        }
        return AlertDto.from(alertRepository.save(alert));
    }

    @Transactional
    public AlertDto resolve(Long id) {
        Alert alert = getEntity(id);
        alert.resolve();
        return AlertDto.from(alertRepository.save(alert));
    }

    @Transactional
    public void delete(Long id) {
        alertRepository.delete(getEntity(id));
    }

    private Alert getEntity(Long id) {
        return alertRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Alerta não encontrado: " + id));
    }
}
