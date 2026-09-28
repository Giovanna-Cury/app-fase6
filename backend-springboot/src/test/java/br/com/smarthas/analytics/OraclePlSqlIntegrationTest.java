package br.com.smarthas.analytics;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

import static br.com.smarthas.support.ApiTestSupport.json;
import static br.com.smarthas.support.ApiTestSupport.login;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Integração ponta a ponta com o Oracle real: REST → Java → JDBC → PL/SQL.
 * Requer o banco do {@code database/docker-compose.yml} no ar e:
 * <pre>SMARTHAS_ORACLE_IT=true mvn test -Dtest=OraclePlSqlIntegrationTest</pre>
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("oracle")
@EnabledIfEnvironmentVariable(named = "SMARTHAS_ORACLE_IT", matches = "true")
class OraclePlSqlIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Autowired
    private SensorAnalyticsGateway gateway;

    @Test
    void oracleGatewayIsActive() {
        assertThat(gateway).isInstanceOf(OraclePlSqlAnalyticsGateway.class);
    }

    @Test
    void criticalReadingIsPersistedByProcedureWithAutomaticAlert() throws Exception {
        String token = login(mockMvc, objectMapper, "operador");

        JsonNode result = json(objectMapper, mockMvc.perform(post("/api/sensors/7/readings")
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"value\": 36.4}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.classification").value("CRITICA"))
                .andExpect(jsonPath("$.engine").value("ORACLE_PLSQL"))
                .andReturn());

        long readingId = result.get("readingId").asLong();
        long alertId = result.get("alertId").asLong();

        // Confirmado no banco: leitura gravada e alerta automático apontando para ela ou para o sensor.
        assertThat(jdbcTemplate.queryForObject(
                "SELECT classificacao FROM shas_leitura WHERE id_leitura = ?", String.class, readingId))
                .isEqualTo("CRITICA");
        assertThat(jdbcTemplate.queryForObject(
                "SELECT origem || '/' || severidade FROM shas_alerta WHERE id_alerta = ? AND id_sensor = 7",
                String.class, alertId))
                .isEqualTo("AUTOMATICO/CRITICAL");
    }

    @Test
    void plSqlBusinessErrorsBecomeHttpErrors() throws Exception {
        String token = login(mockMvc, objectMapper, "operador");

        mockMvc.perform(post("/api/sensors/999/readings")
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"value\": 10}"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Sensor 999 nao encontrado."));

        mockMvc.perform(post("/api/sensors/1/readings")
                        .header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"value\": 999999}"))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void functionsAndRefCursorAreExposedByTheApi() throws Exception {
        String token = login(mockMvc, objectMapper, "admin");

        mockMvc.perform(get("/api/sensors/5/indicators").header("Authorization", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.riskIndex").isNumber())
                .andExpect(jsonPath("$.formattedLastReading")
                        .value(org.hamcrest.Matchers.startsWith("Sensor 05 (Nível de Água) |")));

        mockMvc.perform(get("/api/reports/responsibles").header("Authorization", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(org.hamcrest.Matchers.greaterThanOrEqualTo(3)));

        mockMvc.perform(post("/api/routines/daily-report").header("Authorization", token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.engine").value("ORACLE_PLSQL"));

        mockMvc.perform(post("/api/routines/daily-report?date=2999-01-01").header("Authorization", token))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.message")
                        .value(org.hamcrest.Matchers.startsWith("Data de referencia nao pode estar no futuro")));
    }
}
