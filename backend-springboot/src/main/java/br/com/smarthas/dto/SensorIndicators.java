package br.com.smarthas.dto;

/**
 * Indicadores de um sensor calculados pelas functions PL/SQL.
 *
 * @param conformity24h        FN_CALC_CONFORMIDADE (24h) — % de leituras normais; null sem dados
 * @param conformity7d         FN_CALC_CONFORMIDADE (168h)
 * @param riskIndex            FN_CALC_INDICE_RISCO da localização do sensor (0-100)
 * @param formattedLastReading FN_FORMATAR_LEITURA
 */
public record SensorIndicators(
        Long sensorId,
        Double conformity24h,
        Double conformity7d,
        Integer riskIndex,
        String formattedLastReading,
        String engine
) {
}
