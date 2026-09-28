package br.com.smarthas.dto;

/** Linha do SYS_REFCURSOR devolvido por PRC_RESUMO_POR_RESPONSAVEL. */
public record ResponsibleSummary(
        Long userId,
        String name,
        String role,
        long sensors,
        long sensorsNeedingAttention,
        long readings,
        long criticalReadings,
        long openAlerts,
        Double averageConformity
) {
}
