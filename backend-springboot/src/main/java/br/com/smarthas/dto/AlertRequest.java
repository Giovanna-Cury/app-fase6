package br.com.smarthas.dto;

import br.com.smarthas.model.AlertSeverity;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record AlertRequest(
        @NotBlank(message = "title é obrigatório")
        @Size(max = 150, message = "title deve ter no máximo 150 caracteres") String title,
        @Size(max = 1000, message = "description deve ter no máximo 1000 caracteres") String description,
        @NotNull(message = "severity é obrigatório") AlertSeverity severity,
        @NotBlank(message = "location é obrigatório")
        @Size(max = 150, message = "location deve ter no máximo 150 caracteres") String location,
        Long sensorId
) {
}
