package br.com.smarthas.exception;

/**
 * Violação de regra de negócio (HTTP 422). No perfil Oracle é gerada a partir
 * dos erros -20002..-20004 levantados pelas procedures/functions PL/SQL.
 */
public class BusinessException extends RuntimeException {

    public BusinessException(String message) {
        super(message);
    }
}
