package br.com.smarthas.controller;

import br.com.smarthas.dto.ReadingRegistration;
import br.com.smarthas.dto.ReadingRequest;
import br.com.smarthas.dto.SensorIndicators;
import br.com.smarthas.dto.SensorReadingDto;
import br.com.smarthas.service.SensorReadingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/sensors/{sensorId}")
@Tag(name = "Telemetria", description = "Leituras dos sensores e indicadores calculados em PL/SQL")
@SecurityRequirement(name = "bearerAuth")
public class SensorReadingController {

    private final SensorReadingService readingService;

    public SensorReadingController(SensorReadingService readingService) {
        this.readingService = readingService;
    }

    @PostMapping("/readings")
    @Operation(summary = "Registra uma leitura (aciona PRC_REGISTRAR_LEITURA)",
            description = "Classifica a leitura, atualiza o estado do sensor e gera/escalona alerta automático.")
    public ResponseEntity<ReadingRegistration> register(@PathVariable Long sensorId,
                                                        @Valid @RequestBody ReadingRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(readingService.register(sensorId, request));
    }

    @GetMapping("/readings")
    @Operation(summary = "Histórico de leituras (mais recentes primeiro)")
    public List<SensorReadingDto> history(@PathVariable Long sensorId,
                                          @RequestParam(defaultValue = "48") int limit) {
        return readingService.history(sensorId, limit);
    }

    @GetMapping("/indicators")
    @Operation(summary = "Indicadores do sensor (FN_CALC_CONFORMIDADE, FN_CALC_INDICE_RISCO, FN_FORMATAR_LEITURA)")
    public SensorIndicators indicators(@PathVariable Long sensorId) {
        return readingService.indicators(sensorId);
    }
}
