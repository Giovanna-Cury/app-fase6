package br.com.smarthas.dto;

import br.com.smarthas.model.ExecutionLog;

import java.time.LocalDateTime;

public record ExecutionLogDto(
        Long id,
        String routine,
        String level,
        String message,
        LocalDateTime loggedAt
) {
    public static ExecutionLogDto from(ExecutionLog log) {
        return new ExecutionLogDto(log.getId(), log.getRoutine(), log.getLevel(), log.getMessage(), log.getLoggedAt());
    }
}
