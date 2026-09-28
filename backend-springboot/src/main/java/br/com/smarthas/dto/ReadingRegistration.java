package br.com.smarthas.dto;

import br.com.smarthas.model.ReadingClassification;

/**
 * Resultado de PRC_REGISTRAR_LEITURA (parâmetros OUT da procedure).
 *
 * @param alertId alerta criado, escalonado ou reaproveitado; {@code null} quando a leitura é NORMAL
 * @param engine  quem executou a regra: {@code ORACLE_PLSQL} ou {@code JPA}
 */
public record ReadingRegistration(
        Long readingId,
        Long sensorId,
        double value,
        ReadingClassification classification,
        Long alertId,
        String engine
) {
}
