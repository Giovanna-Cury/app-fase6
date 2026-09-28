package br.com.smarthas.analytics;

import br.com.smarthas.dto.ReadingRegistration;
import br.com.smarthas.dto.ResponsibleSummary;
import br.com.smarthas.dto.SensorIndicators;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Porta (Ports &amp; Adapters) para a inteligência de monitoramento do Smart HAS.
 *
 * <p>Os services dependem só desta interface. Há duas implementações, escolhidas
 * pelo perfil Spring ativo:</p>
 * <ul>
 *   <li>{@link OraclePlSqlAnalyticsGateway} (perfil {@code oracle}): delega às
 *       procedures e functions PL/SQL via JDBC — a regra vive no banco;</li>
 *   <li>{@link JpaAnalyticsGateway} (demais perfis, H2): mesma regra em Java,
 *       para rodar a demo e os testes sem um Oracle disponível.</li>
 * </ul>
 */
public interface SensorAnalyticsGateway {

    /** PRC_REGISTRAR_LEITURA — grava a leitura, atualiza o sensor e gera/escalona alertas. */
    ReadingRegistration registerReading(Long sensorId, double value, LocalDateTime measuredAt);

    /** PRC_GERAR_RELATORIO_DIARIO — consolida o dia e devolve quantos sensores foram processados. */
    int generateDailyReport(LocalDate referenceDate);

    /** PRC_VERIFICAR_SENSORES_INATIVOS — marca como OFFLINE e devolve quantos sensores mudaram. */
    int markInactiveSensors(int toleranceMinutes);

    /** FN_CALC_CONFORMIDADE + FN_CALC_INDICE_RISCO + FN_FORMATAR_LEITURA de um sensor. */
    SensorIndicators indicators(Long sensorId, int windowHours);

    /** PRC_RESUMO_POR_RESPONSAVEL — resumo operacional por usuário responsável. */
    List<ResponsibleSummary> summaryByResponsible(int windowHours);

    /** Identifica o motor em uso ({@code ORACLE_PLSQL} ou {@code JPA}). */
    String engine();
}
