package br.com.smarthas.dto;

import br.com.smarthas.model.Sensor;
import br.com.smarthas.model.SensorStatus;

import java.time.LocalDateTime;

public record SensorDto(
        Long id,
        String name,
        String type,
        SensorStatus status,
        String location,
        Double value,
        String unit,
        Double latitude,
        Double longitude,
        LocalDateTime updatedAt,
        Double alertThreshold,
        Double criticalThreshold,
        Long responsibleId,
        String responsibleName
) {
    public static SensorDto from(Sensor sensor) {
        var responsible = sensor.getResponsible();
        return new SensorDto(
                sensor.getId(),
                sensor.getName(),
                sensor.getType(),
                sensor.getStatus(),
                sensor.getLocation(),
                sensor.getValue(),
                sensor.getUnit(),
                sensor.getLatitude(),
                sensor.getLongitude(),
                sensor.getUpdatedAt(),
                sensor.getAlertThreshold(),
                sensor.getCriticalThreshold(),
                responsible != null ? responsible.getId() : null,
                responsible != null ? responsible.getName() : null
        );
    }
}
