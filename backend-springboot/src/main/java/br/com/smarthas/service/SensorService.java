package br.com.smarthas.service;

import br.com.smarthas.dto.SensorDto;
import br.com.smarthas.dto.SensorRequest;
import br.com.smarthas.exception.BusinessException;
import br.com.smarthas.exception.NotFoundException;
import br.com.smarthas.model.Sensor;
import br.com.smarthas.model.User;
import br.com.smarthas.repository.SensorRepository;
import br.com.smarthas.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class SensorService {

    private final SensorRepository sensorRepository;
    private final UserRepository userRepository;

    public SensorService(SensorRepository sensorRepository, UserRepository userRepository) {
        this.sensorRepository = sensorRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<SensorDto> findAll() {
        return sensorRepository.findAllByOrderByIdAsc().stream()
                .map(SensorDto::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public SensorDto findById(Long id) {
        return SensorDto.from(getEntity(id));
    }

    @Transactional
    public SensorDto create(SensorRequest request) {
        Sensor sensor = new Sensor(
                request.name(),
                request.type(),
                request.status(),
                request.location(),
                request.value(),
                request.unit(),
                request.latitude(),
                request.longitude(),
                LocalDateTime.now()
        );
        applyMonitoringRules(sensor, request);
        return SensorDto.from(sensorRepository.save(sensor));
    }

    @Transactional
    public SensorDto update(Long id, SensorRequest request) {
        Sensor sensor = getEntity(id);
        sensor.setName(request.name());
        sensor.setType(request.type());
        sensor.setStatus(request.status());
        sensor.setLocation(request.location());
        sensor.setValue(request.value());
        sensor.setUnit(request.unit());
        sensor.setLatitude(request.latitude());
        sensor.setLongitude(request.longitude());
        sensor.setUpdatedAt(LocalDateTime.now());
        applyMonitoringRules(sensor, request);
        return SensorDto.from(sensorRepository.save(sensor));
    }

    @Transactional
    public void delete(Long id) {
        sensorRepository.delete(getEntity(id));
    }

    /** Limites e responsável: mesmas regras da constraint CK_SHAS_SENSOR_LIMITES. */
    private void applyMonitoringRules(Sensor sensor, SensorRequest request) {
        if (request.alertThreshold() != null && request.criticalThreshold() != null
                && request.criticalThreshold() < request.alertThreshold()) {
            throw new BusinessException("criticalThreshold deve ser maior ou igual a alertThreshold.");
        }
        sensor.setAlertThreshold(request.alertThreshold());
        sensor.setCriticalThreshold(request.criticalThreshold());

        User responsible = null;
        if (request.responsibleId() != null) {
            responsible = userRepository.findById(request.responsibleId())
                    .orElseThrow(() -> new NotFoundException("Usuário não encontrado: " + request.responsibleId()));
        }
        sensor.setResponsible(responsible);
    }

    private Sensor getEntity(Long id) {
        return sensorRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Sensor não encontrado: " + id));
    }
}
