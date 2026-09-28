package br.com.smarthas.dto;

public record AuthResponse(
        String token,
        UserDto user
) {
}
