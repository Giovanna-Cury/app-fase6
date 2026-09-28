package br.com.smarthas.dto;

import br.com.smarthas.model.Role;
import br.com.smarthas.model.User;

public record UserDto(
        Long id,
        String name,
        String username,
        String email,
        Role role
) {
    public static UserDto from(User user) {
        return new UserDto(
                user.getId(),
                user.getName(),
                user.getUsername(),
                user.getEmail(),
                user.getRole()
        );
    }
}
