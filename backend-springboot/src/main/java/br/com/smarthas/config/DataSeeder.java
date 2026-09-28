package br.com.smarthas.config;

import br.com.smarthas.analytics.SensorAnalyticsGateway;
import br.com.smarthas.model.Alert;
import br.com.smarthas.model.AlertOrigin;
import br.com.smarthas.model.AlertSeverity;
import br.com.smarthas.model.ReadingClassification;
import br.com.smarthas.model.Role;
import br.com.smarthas.model.Sensor;
import br.com.smarthas.model.SensorReading;
import br.com.smarthas.model.SensorStatus;
import br.com.smarthas.model.User;
import br.com.smarthas.repository.AlertRepository;
import br.com.smarthas.repository.SensorReadingRepository;
import br.com.smarthas.repository.SensorRepository;
import br.com.smarthas.repository.UserRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

/**
 * Dados de demonstração para o perfil H2. No perfil {@code oracle} a carga é
 * feita por {@code database/scripts/04_carga_dados.sql} (PL/SQL), por isso
 * este seeder não roda lá.
 */
@Component
@Profile("!oracle")
public class DataSeeder implements CommandLineRunner {

    private static final int HISTORY_HOURS = 48;

    private final UserRepository userRepository;
    private final SensorRepository sensorRepository;
    private final SensorReadingRepository readingRepository;
    private final AlertRepository alertRepository;
    private final SensorAnalyticsGateway analyticsGateway;
    private final PasswordEncoder passwordEncoder;

    public DataSeeder(UserRepository userRepository,
                      SensorRepository sensorRepository,
                      SensorReadingRepository readingRepository,
                      AlertRepository alertRepository,
                      SensorAnalyticsGateway analyticsGateway,
                      PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.sensorRepository = sensorRepository;
        this.readingRepository = readingRepository;
        this.alertRepository = alertRepository;
        this.analyticsGateway = analyticsGateway;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public void run(String... args) {
        if (userRepository.count() > 0) {
            return;
        }
        List<User> users = seedUsers();
        List<Sensor> sensors = seedSensors(users);
        seedReadings(sensors);
        seedManualAlerts();

        // Mesmos "eventos" da carga Oracle, agora pelo gateway (regra em Java).
        analyticsGateway.registerReading(sensors.get(2).getId(), 162.4, null);
        analyticsGateway.registerReading(sensors.get(4).getId(), 78.5, null);
        analyticsGateway.registerReading(sensors.get(4).getId(), 91.2, null);
        analyticsGateway.markInactiveSensors(60);
        analyticsGateway.generateDailyReport(LocalDate.now().minusDays(1));
        analyticsGateway.generateDailyReport(LocalDate.now());
    }

    private List<User> seedUsers() {
        String hash = passwordEncoder.encode("1234");
        return userRepository.saveAll(List.of(
                new User("Administrador", "admin", "admin@smarthas.com", hash, Role.ADMIN),
                new User("Operador", "operador", "operador@smarthas.com", hash, Role.OPERATOR),
                new User("Equipe de Campo", "campo", "campo@smarthas.com", hash, Role.OPERATOR)));
    }

    private List<Sensor> seedSensors(List<User> users) {
        User admin = users.get(0);
        User operator = users.get(1);
        User field = users.get(2);
        LocalDateTime now = LocalDateTime.now();
        return sensorRepository.saveAll(List.of(
                sensor("Sensor 01", "Temperatura", "Centro de São Paulo", "°C", -23.5505, -46.6333, 30, 35, operator, now),
                sensor("Sensor 02", "Umidade", "Avenida Paulista", "%", -23.5614, -46.6559, 85, 95, operator, now),
                sensor("Sensor 03", "Qualidade do Ar", "Parque Ibirapuera", "AQI", -23.5874, -46.6576, 80, 150, operator, now),
                sensor("Sensor 04", "Movimento", "Estação da Luz", "un", -23.5340, -46.6357, 60, 100, admin, now),
                sensor("Sensor 05", "Nível de Água", "Marginal Tietê", "%", -23.5170, -46.6200, 70, 90, field, now),
                sensor("Sensor 06", "Ruído", "Rua 25 de Março", "dB", -23.5435, -46.6310, 75, 85, operator, now),
                sensor("Sensor 07", "Temperatura", "Itaquera - Zona Leste", "°C", -23.5400, -46.4560, 30, 35, field, now),
                sensor("Sensor 08", "Nível de Água", "Córrego Pirajuçara", "%", -23.6040, -46.7420, 70, 90, field, now)));
    }

    private static Sensor sensor(String name, String type, String location, String unit,
                                 double lat, double lon, double alert, double critical,
                                 User responsible, LocalDateTime now) {
        Sensor sensor = new Sensor(name, type, SensorStatus.ONLINE, location, null, unit, lat, lon, now);
        sensor.setAlertThreshold(alert);
        sensor.setCriticalThreshold(critical);
        sensor.setResponsible(responsible);
        return sensor;
    }

    /** Série horária simulada: base + ciclo diário + ruído + picos ocasionais. */
    private void seedReadings(List<Sensor> sensors) {
        double[][] profiles = {
                {24, 5, 1.2}, {62, 12, 3}, {72, 14, 6}, {28, 22, 6},
                {55, 8, 3.5}, {63, 9, 2.5}, {26, 5, 1.2}, {48, 10, 4.5}};
        Random random = new Random(2026);
        LocalDateTime now = LocalDateTime.now().truncatedTo(ChronoUnit.HOURS);
        List<SensorReading> readings = new ArrayList<>();

        for (int s = 0; s < sensors.size(); s++) {
            Sensor sensor = sensors.get(s);
            double base = profiles[s][0];
            double amplitude = profiles[s][1];
            double noise = profiles[s][2];
            // Sensor 04 parou de comunicar há ~3h (o watchdog o marcará OFFLINE).
            int skipLast = s == 3 ? 3 : 0;
            SensorReading last = null;

            for (int h = HISTORY_HOURS - 1; h >= skipLast; h--) {
                LocalDateTime readAt = now.minusHours(h);
                double value = base + amplitude * Math.sin(2 * Math.PI * (readAt.getHour() - 9) / 24.0)
                        + random.nextGaussian() * noise;
                if (random.nextDouble() < 0.02) {
                    value = sensor.getCriticalThreshold() + random.nextDouble() * amplitude;
                }
                value = Math.round(Math.max(0, value) * 100.0) / 100.0;
                ReadingClassification classification =
                        ReadingClassification.of(value, sensor.getAlertThreshold(), sensor.getCriticalThreshold());
                last = new SensorReading(sensor, value, classification, readAt);
                readings.add(last);
            }
            sensor.setValue(last.getValue());
            sensor.setUpdatedAt(last.getReadAt());
            sensor.setStatus(last.getClassification() == ReadingClassification.NORMAL
                    ? SensorStatus.ONLINE : SensorStatus.WARNING);
        }
        readingRepository.saveAll(readings);
        sensorRepository.saveAll(sensors);
    }

    private void seedManualAlerts() {
        LocalDateTime now = LocalDateTime.now();
        alertRepository.saveAll(List.of(
                manual("Área de risco detectada", "Movimentação anômala identificada pela camada de IA.",
                        AlertSeverity.CRITICAL, "Centro de São Paulo", now.minusHours(1)),
                manual("Alagamento reportado por moradores", "Relatos de ruas com água acumulada próximas à marginal.",
                        AlertSeverity.HIGH, "Marginal Tietê", now.minusHours(3))));
    }

    private static Alert manual(String title, String description, AlertSeverity severity,
                                String location, LocalDateTime createdAt) {
        Alert alert = new Alert(title, description, severity, location, createdAt, false);
        alert.setOrigin(AlertOrigin.MANUAL);
        return alert;
    }
}
