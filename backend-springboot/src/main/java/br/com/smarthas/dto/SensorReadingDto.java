package br.com.smarthas.dto;

import br.com.smarthas.model.ReadingClassification;
import br.com.smarthas.model.SensorReading;

import java.time.LocalDateTime;

public record SensorReadingDto(
        Long id,
        Double value,
        ReadingClassification classification,
        LocalDateTime readAt
) {
    public static SensorReadingDto from(SensorReading reading) {
        return new SensorReadingDto(
                reading.getId(),
                reading.getValue(),
                reading.getClassification(),
                reading.getReadAt()
        );
    }
}
