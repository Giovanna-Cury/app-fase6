package br.com.smarthas.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;

import static br.com.smarthas.support.ApiTestSupport.json;
import static br.com.smarthas.support.ApiTestSupport.login;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Fluxo de telemetria no perfil H2 (JpaAnalyticsGateway). O mesmo contrato é
 * verificado contra o Oracle real em {@code OraclePlSqlIntegrationTest}.
 * Sensor 1 = Temperatura com limites 30 (alerta) / 35 (crítico).
 */
@SpringBootTest
@AutoConfigureMockMvc
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class SensorReadingIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private String operator;
    private String admin;

    @BeforeEach
    void setUp() throws Exception {
        operator = login(mockMvc, objectMapper, "operador");
        admin = login(mockMvc, objectMapper, "admin");
    }

    @Test
    void normalReadingUpdatesSensorWithoutAlert() throws Exception {
        registerReading(1, 25.0)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.classification").value("NORMAL"))
                .andExpect(jsonPath("$.alertId").isEmpty())
                .andExpect(jsonPath("$.readingId").isNumber());

        mockMvc.perform(get("/api/sensors/1").header("Authorization", operator))
                .andExpect(jsonPath("$.value").value(25.0))
                .andExpect(jsonPath("$.status").value("ONLINE"));
    }

    @Test
    void alertThenCriticalReadingReusesAndEscalatesSameAlert() throws Exception {
        JsonNode first = json(objectMapper, registerReading(1, 31.0)
                .andExpect(jsonPath("$.classification").value("ALERTA"))
                .andReturn());
        long alertId = first.get("alertId").asLong();

        JsonNode second = json(objectMapper, registerReading(1, 36.5)
                .andExpect(jsonPath("$.classification").value("CRITICA"))
                .andReturn());
        assertThat(second.get("alertId").asLong()).isEqualTo(alertId);

        mockMvc.perform(get("/api/alerts/" + alertId).header("Authorization", operator))
                .andExpect(jsonPath("$.severity").value("CRITICAL"))
                .andExpect(jsonPath("$.origin").value("AUTOMATICO"))
                .andExpect(jsonPath("$.sensorId").value(1));

        mockMvc.perform(get("/api/sensors/1").header("Authorization", operator))
                .andExpect(jsonPath("$.status").value("WARNING"));
    }

    @Test
    void unknownSensorReturns404() throws Exception {
        registerReading(999, 10.0)
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Sensor 999 nao encontrado."));
    }

    @Test
    void outOfRangeValueReturns422() throws Exception {
        registerReading(1, 999999.0)
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.message").isNotEmpty());
    }

    @Test
    void missingValueReturns422() throws Exception {
        mockMvc.perform(post("/api/sensors/1/readings")
                        .header("Authorization", operator)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.message").value("value é obrigatório"));
    }

    @Test
    void historyAndIndicatorsReflectNewReading() throws Exception {
        registerReading(1, 37.8).andExpect(status().isCreated());

        mockMvc.perform(get("/api/sensors/1/readings?limit=5").header("Authorization", operator))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(5))
                .andExpect(jsonPath("$[0].value").value(37.8))
                .andExpect(jsonPath("$[0].classification").value("CRITICA"));

        mockMvc.perform(get("/api/sensors/1/indicators").header("Authorization", operator))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.conformity24h").isNumber())
                .andExpect(jsonPath("$.riskIndex").isNumber())
                .andExpect(jsonPath("$.formattedLastReading")
                        .value(org.hamcrest.Matchers.startsWith("Sensor 01 (Temperatura) | 37,80 °C | CRITICA")))
                .andExpect(jsonPath("$.engine").value("JPA"));
    }

    @Test
    void routinesAreAdminOnlyAndProduceReports() throws Exception {
        mockMvc.perform(post("/api/routines/daily-report").header("Authorization", operator))
                .andExpect(status().isForbidden());

        mockMvc.perform(post("/api/routines/daily-report").header("Authorization", admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.routine").value("PRC_GERAR_RELATORIO_DIARIO"))
                .andExpect(jsonPath("$.processed").value(8));

        mockMvc.perform(get("/api/reports/daily").header("Authorization", operator))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(8))
                .andExpect(jsonPath("$[0].summary").isNotEmpty());

        mockMvc.perform(post("/api/routines/daily-report?date=2999-01-01").header("Authorization", admin))
                .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void responsibleSummaryListsEveryUser() throws Exception {
        mockMvc.perform(get("/api/reports/responsibles").header("Authorization", operator))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(3))
                .andExpect(jsonPath("$[0].openAlerts").isNumber());
    }

    @Test
    void inactiveSensorRoutineValidatesTolerance() throws Exception {
        mockMvc.perform(post("/api/routines/inactive-sensors?toleranceMinutes=0").header("Authorization", admin))
                .andExpect(status().isUnprocessableEntity());

        mockMvc.perform(post("/api/routines/inactive-sensors?toleranceMinutes=60").header("Authorization", admin))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.processed").isNumber());
    }

    private ResultActions registerReading(long sensorId, double value) throws Exception {
        return mockMvc.perform(post("/api/sensors/" + sensorId + "/readings")
                .header("Authorization", operator)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":" + value + "}"));
    }
}
