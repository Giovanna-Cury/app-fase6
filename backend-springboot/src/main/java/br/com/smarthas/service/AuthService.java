package br.com.smarthas.service;

import br.com.smarthas.dto.AuthResponse;
import br.com.smarthas.dto.LoginRequest;
import br.com.smarthas.dto.UserDto;
import br.com.smarthas.model.User;
import br.com.smarthas.repository.UserRepository;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByUsername(request.username())
                .orElseThrow(() -> new BadCredentialsException("Usuário ou senha inválidos."));

        if (!passwordEncoder.matches(request.password(), user.getPassword())) {
            throw new BadCredentialsException("Usuário ou senha inválidos.");
        }

        String token = jwtService.generateToken(user.getUsername(), user.getRole().name());
        return new AuthResponse(token, UserDto.from(user));
    }
}
