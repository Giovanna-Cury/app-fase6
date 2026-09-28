package br.com.smarthas.dto;

import br.com.smarthas.model.SensorStatus;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record SensorRequest(
        @NotBlank(message = "name é obrigatório")
        @Size(max = 100, message = "name deve ter no máximo 100 caracteres") String name,
        @NotBlank(message = "type é obrigatório")
        @Size(max = 50, message = "type deve ter no máximo 50 caracteres") String type,
        @NotNull(message = "status é obrigatório") SensorStatus status,
        @NotBlank(message = "location é obrigatório")
        @Size(max = 150, message = "location deve ter no máximo 150 caracteres") String location,
        Double value,
        @Size(max = 20, message = "unit deve ter no máximo 20 caracteres") String unit,
        @DecimalMin(value = "-90", message = "latitude inválida")
        @DecimalMax(value = "90", message = "latitude inválida") Double latitude,
        @DecimalMin(value = "-180", message = "longitude inválida")
        @DecimalMax(value = "180", message = "longitude inválida") Double longitude,
        Double alertThreshold,
        Double criticalThreshold,
        Long responsibleId
) {
}
