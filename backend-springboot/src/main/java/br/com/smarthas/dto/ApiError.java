package br.com.smarthas.dto;

import java.time.LocalDateTime;

public record ApiError(
        String message,
        int status,
        LocalDateTime timestamp
) {
    public static ApiError of(String message, int status) {
        return new ApiError(message, status, LocalDateTime.now());
    }
}
