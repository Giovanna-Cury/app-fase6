package br.com.smarthas.analytics;

import br.com.smarthas.exception.BusinessException;
import br.com.smarthas.exception.NotFoundException;
import org.springframework.dao.DataAccessException;

import java.sql.SQLException;

/**
 * Traduz os erros de negócio do PL/SQL (RAISE_APPLICATION_ERROR) em exceções
 * de domínio, que o {@code GlobalExceptionHandler} converte em HTTP:
 * <pre>
 *   ORA-20001 (sensor inexistente)           -> NotFoundException  -> 404
 *   ORA-20002..20004 (valor/parâmetro/data)  -> BusinessException  -> 422
 * </pre>
 * Qualquer outro erro segue como {@link DataAccessException} (500).
 */
final class OracleErrorTranslator {

    static final int SENSOR_NOT_FOUND = 20001;
    static final int FIRST_BUSINESS_ERROR = 20002;
    static final int LAST_BUSINESS_ERROR = 20004;

    private OracleErrorTranslator() {
    }

    static RuntimeException translate(DataAccessException ex) {
        SQLException sql = findSqlException(ex);
        if (sql == null) {
            return ex;
        }
        int code = sql.getErrorCode();
        if (code == SENSOR_NOT_FOUND) {
            return new NotFoundException(cleanMessage(sql.getMessage(), code));
        }
        if (code >= FIRST_BUSINESS_ERROR && code <= LAST_BUSINESS_ERROR) {
            return new BusinessException(cleanMessage(sql.getMessage(), code));
        }
        return ex;
    }

    /**
     * Extrai só o texto de negócio de uma mensagem Oracle, descartando o
     * prefixo e a pilha ({@code ORA-06512: at ...}).
     */
    static String cleanMessage(String raw, int code) {
        if (raw == null) {
            return "Erro de negócio.";
        }
        String prefix = String.format("ORA-%05d: ", code);
        return raw.lines()
                .filter(line -> line.contains(prefix))
                .findFirst()
                .map(line -> line.substring(line.indexOf(prefix) + prefix.length()).trim())
                .orElse(raw.lines().findFirst().orElse(raw).trim());
    }

    private static SQLException findSqlException(Throwable ex) {
        Throwable current = ex;
        while (current != null) {
            if (current instanceof SQLException sql) {
                return sql;
            }
            current = current.getCause();
        }
        return null;
    }
}
