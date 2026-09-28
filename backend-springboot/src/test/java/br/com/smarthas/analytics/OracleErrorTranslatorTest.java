package br.com.smarthas.analytics;

import br.com.smarthas.exception.BusinessException;
import br.com.smarthas.exception.NotFoundException;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.UncategorizedSQLException;

import java.sql.SQLException;

import static org.assertj.core.api.Assertions.assertThat;

class OracleErrorTranslatorTest {

    @Test
    void sensorNotFoundBecomes404Exception() {
        RuntimeException translated = OracleErrorTranslator.translate(oracleError(20001,
                "ORA-20001: Sensor 999 nao encontrado.\nORA-06512: at \"SMARTHAS.PRC_REGISTRAR_LEITURA\", line 150"));

        assertThat(translated)
                .isInstanceOf(NotFoundException.class)
                .hasMessage("Sensor 999 nao encontrado.");
    }

    @Test
    void businessErrorsBecome422Exception() {
        for (int code = 20002; code <= 20004; code++) {
            RuntimeException translated = OracleErrorTranslator.translate(
                    oracleError(code, "ORA-" + code + ": Regra violada.\nORA-06512: at line 1"));
            assertThat(translated).isInstanceOf(BusinessException.class).hasMessage("Regra violada.");
        }
    }

    @Test
    void technicalErrorsAreKept() {
        DataAccessException original = oracleError(1, "ORA-00001: unique constraint violated");

        assertThat(OracleErrorTranslator.translate(original)).isSameAs(original);
    }

    private static DataAccessException oracleError(int code, String message) {
        return new UncategorizedSQLException("call", "{call X}", new SQLException(message, "72000", code));
    }
}
