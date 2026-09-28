package br.com.smarthas.analytics;

import br.com.smarthas.dto.ReadingRegistration;
import br.com.smarthas.dto.ResponsibleSummary;
import br.com.smarthas.dto.SensorIndicators;
import br.com.smarthas.exception.NotFoundException;
import br.com.smarthas.model.ReadingClassification;
import oracle.jdbc.OracleTypes;
import org.springframework.context.annotation.Profile;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.SqlOutParameter;
import org.springframework.jdbc.core.SqlParameter;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;

/**
 * Adapter Oracle: a regra de negócio roda no banco (PL/SQL) e o Java apenas
 * orquestra a chamada. Fluxo: REST (Controller) → Service → este gateway →
 * JDBC ({@link SimpleJdbcCall}/{@link JdbcTemplate}) → procedures/functions.
 *
 * <p>Os {@link SimpleJdbcCall} usam parâmetros declarados explicitamente e
 * <em>named binding</em> ({@code p_x => ?}): não dependem de metadados do
 * dicionário de dados nem da ordem dos parâmetros na assinatura.</p>
 */
@Component
@Profile("oracle")
public class OraclePlSqlAnalyticsGateway implements SensorAnalyticsGateway {

    public static final String ENGINE = "ORACLE_PLSQL";

    private static final int WEEK_HOURS = 24 * 7;

    /** Três functions PL/SQL compostas numa única consulta SQL. */
    private static final String INDICATORS_SQL = """
            SELECT s.id_sensor,
                   fn_calc_conformidade(s.id_sensor, ?) AS conf_janela,
                   fn_calc_conformidade(s.id_sensor, ?) AS conf_7d,
                   fn_calc_indice_risco(s.localizacao)  AS indice_risco,
                   fn_formatar_leitura(s.id_sensor)     AS ultima_leitura
              FROM shas_sensor s
             WHERE s.id_sensor = ?
            """;

    private static final RowMapper<ResponsibleSummary> RESPONSIBLE_MAPPER = (rs, rowNum) -> new ResponsibleSummary(
            rs.getLong("id_usuario"),
            rs.getString("nome"),
            rs.getString("perfil"),
            rs.getLong("qtd_sensores"),
            rs.getLong("qtd_sensores_atencao"),
            rs.getLong("qtd_leituras"),
            rs.getLong("qtd_criticas"),
            rs.getLong("alertas_abertos"),
            nullableDouble(rs, "conformidade_media"));

    private final JdbcTemplate jdbcTemplate;
    private final SimpleJdbcCall registerReadingCall;
    private final SimpleJdbcCall dailyReportCall;
    private final SimpleJdbcCall inactiveSensorsCall;
    private final SimpleJdbcCall responsibleSummaryCall;

    public OraclePlSqlAnalyticsGateway(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;

        this.registerReadingCall = procedure("PRC_REGISTRAR_LEITURA",
                new SqlParameter("p_id_sensor", Types.NUMERIC),
                new SqlParameter("p_valor", Types.NUMERIC),
                new SqlParameter("p_dt_leitura", Types.TIMESTAMP),
                new SqlOutParameter("p_id_leitura", Types.NUMERIC),
                new SqlOutParameter("p_classificacao", Types.VARCHAR),
                new SqlOutParameter("p_id_alerta", Types.NUMERIC));

        this.dailyReportCall = procedure("PRC_GERAR_RELATORIO_DIARIO",
                new SqlParameter("p_dt_referencia", Types.DATE),
                new SqlOutParameter("p_qtd_processados", Types.NUMERIC));

        this.inactiveSensorsCall = procedure("PRC_VERIFICAR_SENSORES_INATIVOS",
                new SqlParameter("p_minutos", Types.NUMERIC),
                new SqlOutParameter("p_qtd_offline", Types.NUMERIC));

        // SYS_REFCURSOR (OUT) lido como ResultSet e mapeado linha a linha.
        this.responsibleSummaryCall = procedure("PRC_RESUMO_POR_RESPONSAVEL",
                new SqlParameter("p_horas", Types.NUMERIC),
                new SqlOutParameter("p_cursor", OracleTypes.CURSOR, RESPONSIBLE_MAPPER));
    }

    @Override
    public ReadingRegistration registerReading(Long sensorId, double value, LocalDateTime measuredAt) {
        Map<String, Object> out = call(() -> registerReadingCall.execute(new MapSqlParameterSource()
                .addValue("p_id_sensor", sensorId)
                .addValue("p_valor", BigDecimal.valueOf(value))
                .addValue("p_dt_leitura", measuredAt != null ? Timestamp.valueOf(measuredAt) : null)));

        return new ReadingRegistration(
                toLong(out.get("p_id_leitura")),
                sensorId,
                value,
                ReadingClassification.valueOf((String) out.get("p_classificacao")),
                toLong(out.get("p_id_alerta")),
                ENGINE);
    }

    @Override
    public int generateDailyReport(LocalDate referenceDate) {
        Map<String, Object> out = call(() -> dailyReportCall.execute(new MapSqlParameterSource()
                .addValue("p_dt_referencia", Date.valueOf(referenceDate))));
        return toInt(out.get("p_qtd_processados"));
    }

    @Override
    public int markInactiveSensors(int toleranceMinutes) {
        Map<String, Object> out = call(() -> inactiveSensorsCall.execute(new MapSqlParameterSource()
                .addValue("p_minutos", toleranceMinutes)));
        return toInt(out.get("p_qtd_offline"));
    }

    @Override
    public SensorIndicators indicators(Long sensorId, int windowHours) {
        try {
            return call(() -> jdbcTemplate.queryForObject(INDICATORS_SQL,
                    (rs, rowNum) -> new SensorIndicators(
                            rs.getLong("id_sensor"),
                            nullableDouble(rs, "conf_janela"),
                            nullableDouble(rs, "conf_7d"),
                            rs.getInt("indice_risco"),
                            rs.getString("ultima_leitura"),
                            ENGINE),
                    windowHours, WEEK_HOURS, sensorId));
        } catch (EmptyResultDataAccessException ex) {
            throw new NotFoundException("Sensor não encontrado: " + sensorId);
        }
    }

    @Override
    @SuppressWarnings("unchecked")
    public List<ResponsibleSummary> summaryByResponsible(int windowHours) {
        Map<String, Object> out = call(() -> responsibleSummaryCall.execute(new MapSqlParameterSource()
                .addValue("p_horas", windowHours)));
        return (List<ResponsibleSummary>) out.get("p_cursor");
    }

    @Override
    public String engine() {
        return ENGINE;
    }

    private SimpleJdbcCall procedure(String name, SqlParameter... parameters) {
        return new SimpleJdbcCall(jdbcTemplate)
                .withProcedureName(name)
                .withoutProcedureColumnMetaDataAccess()
                .withNamedBinding()
                .declareParameters(parameters);
    }

    /** Executa a chamada traduzindo ORA-2000x em exceções de domínio. */
    private static <T> T call(Supplier<T> jdbcCall) {
        try {
            return jdbcCall.get();
        } catch (EmptyResultDataAccessException ex) {
            throw ex;
        } catch (DataAccessException ex) {
            throw OracleErrorTranslator.translate(ex);
        }
    }

    private static Long toLong(Object number) {
        return number == null ? null : ((Number) number).longValue();
    }

    private static int toInt(Object number) {
        return number == null ? 0 : ((Number) number).intValue();
    }

    private static Double nullableDouble(ResultSet rs, String column) throws SQLException {
        BigDecimal value = rs.getBigDecimal(column);
        return value == null ? null : value.doubleValue();
    }
}
