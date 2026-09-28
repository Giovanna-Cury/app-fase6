package br.com.smarthas.dto;

import java.time.LocalDateTime;

/** Resultado da execução de uma rotina batch (procedure) disparada pela API. */
public record RoutineResult(
        String routine,
        int processed,
        String engine,
        LocalDateTime executedAt
) {
}
