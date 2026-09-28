package br.com.smarthas.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;

import java.time.LocalDateTime;

/**
 * Leitura enviada por um sensor/gateway IoT.
 *
 * @param value      valor medido (obrigatório)
 * @param measuredAt momento da medição; se omitido, o banco usa o horário atual
 */
public record ReadingRequest(
        @NotNull(message = "value é obrigatório") Double value,
        @PastOrPresent(message = "measuredAt não pode estar no futuro") LocalDateTime measuredAt
) {
}
