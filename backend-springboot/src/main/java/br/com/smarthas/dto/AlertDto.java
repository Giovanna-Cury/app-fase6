package br.com.smarthas.dto;

import br.com.smarthas.model.Alert;
import br.com.smarthas.model.AlertOrigin;
import br.com.smarthas.model.AlertSeverity;

import java.time.LocalDateTime;

public record AlertDto(
        Long id,
        String title,
        String description,
        AlertSeverity severity,
        String location,
        LocalDateTime createdAt,
        boolean resolved,
        AlertOrigin origin,
        Long sensorId,
        LocalDateTime resolvedAt
) {
    public static AlertDto from(Alert alert) {
        return new AlertDto(
                alert.getId(),
                alert.getTitle(),
                alert.getDescription(),
                alert.getSeverity(),
                alert.getLocation(),
                alert.getCreatedAt(),
                alert.isResolved(),
                alert.getOrigin(),
                alert.getSensor() != null ? alert.getSensor().getId() : null,
                alert.getResolvedAt()
        );
    }
}
