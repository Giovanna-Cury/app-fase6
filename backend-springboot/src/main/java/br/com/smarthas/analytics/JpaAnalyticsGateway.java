package br.com.smarthas.analytics;

import br.com.smarthas.dto.ReadingRegistration;
import br.com.smarthas.dto.ResponsibleSummary;
import br.com.smarthas.dto.SensorIndicators;
import br.com.smarthas.exception.BusinessException;
import br.com.smarthas.exception.NotFoundException;
import br.com.smarthas.model.Alert;
import br.com.smarthas.model.AlertOrigin;
import br.com.smarthas.model.AlertSeverity;
import br.com.smarthas.model.DailyReport;
import br.com.smarthas.model.ExecutionLog;
import br.com.smarthas.model.ReadingClassification;
import br.com.smarthas.model.Sensor;
import br.com.smarthas.model.SensorReading;
import br.com.smarthas.model.SensorStatus;
import br.com.smarthas.model.User;
import br.com.smarthas.repository.AlertRepository;
import br.com.smarthas.repository.DailyReportRepository;
import br.com.smarthas.repository.ExecutionLogRepository;
import br.com.smarthas.repository.SensorReadingRepository;
import br.com.smarthas.repository.SensorRepository;
import br.com.smarthas.repository.UserRepository;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.DoubleSummaryStatistics;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

/**
 * Adapter sem Oracle (H2): reproduz em Java as regras das rotinas PL/SQL para
 * que a API, a demo e os testes funcionem sem um banco Oracle disponível.
 * O comportamento (códigos de erro, deduplicação/escalonamento de alertas,
 * fórmulas dos indicadores e textos) espelha os scripts em {@code database/scripts}.
 */
@Component
@Profile("!oracle")
public class JpaAnalyticsGateway implements SensorAnalyticsGateway {

    public static final String ENGINE = "JPA";

    private static final double MIN_VALUE = -1000;
    private static final double MAX_VALUE = 100000;
    private static final String OFFLINE_ALERT_PREFIX = "Sensor sem comunicação: ";
    private static final Locale PT_BR = Locale.forLanguageTag("pt-BR");
    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    private final SensorRepository sensorRepository;
    private final SensorReadingRepository readingRepository;
    private final AlertRepository alertRepository;
    private final DailyReportRepository reportRepository;
    private final UserRepository userRepository;
    private final ExecutionLogRepository logRepository;

    public JpaAnalyticsGateway(SensorRepository sensorRepository,
                               SensorReadingRepository readingRepository,
                               AlertRepository alertRepository,
                               DailyReportRepository reportRepository,
                               UserRepository userRepository,
                               ExecutionLogRepository logRepository) {
        this.sensorRepository = sensorRepository;
        this.readingRepository = readingRepository;
        this.alertRepository = alertRepository;
        this.reportRepository = reportRepository;
        this.userRepository = userRepository;
        this.logRepository = logRepository;
    }

    @Override
    @Transactional
    public ReadingRegistration registerReading(Long sensorId, double value, LocalDateTime measuredAt) {
        LocalDateTime readAt = measuredAt != null ? measuredAt : LocalDateTime.now();
        if (value < MIN_VALUE || value > MAX_VALUE || readAt.isAfter(LocalDateTime.now().plusMinutes(5))) {
            throw new BusinessException("Valor de leitura invalido: informe um numero entre -1000 e 100000 "
                    + "e uma data que nao esteja no futuro.");
        }
        Sensor sensor = sensorRepository.findById(sensorId)
                .orElseThrow(() -> new NotFoundException("Sensor " + sensorId + " nao encontrado."));

        ReadingClassification classification =
                ReadingClassification.of(value, sensor.getAlertThreshold(), sensor.getCriticalThreshold());
        SensorReading reading = readingRepository.save(new SensorReading(sensor, value, classification, readAt));

        if (!readAt.isBefore(sensor.getUpdatedAt())) {
            sensor.setValue(value);
            sensor.setStatus(classification == ReadingClassification.NORMAL ? SensorStatus.ONLINE : SensorStatus.WARNING);
            sensor.setUpdatedAt(readAt);
        }

        Long alertId = classification == ReadingClassification.NORMAL
                ? null
                : raiseOrEscalateAlert(sensor, reading, classification);

        return new ReadingRegistration(reading.getId(), sensorId, value, classification, alertId, ENGINE);
    }

    private Long raiseOrEscalateAlert(Sensor sensor, SensorReading reading, ReadingClassification classification) {
        AlertSeverity severity = classification == ReadingClassification.CRITICA
                ? AlertSeverity.CRITICAL : AlertSeverity.MEDIUM;
        String label = sensor.getName() + " (" + sensor.getType() + ")";
        String valueText = fmt(reading.getValue()) + " " + sensor.getUnit();

        var open = alertRepository.findFirstBySensorIdAndResolvedFalseAndOriginOrderByCreatedAtDesc(
                sensor.getId(), AlertOrigin.AUTOMATICO);
        if (open.isEmpty()) {
            Alert alert = new Alert(
                    (severity == AlertSeverity.CRITICAL ? "Leitura crítica: " : "Leitura acima do limite: ") + label,
                    "Sensor registrou " + valueText + " (limite de alerta " + fmt(sensor.getAlertThreshold())
                            + ", crítico " + fmt(sensor.getCriticalThreshold()) + ").",
                    severity, sensor.getLocation(), reading.getReadAt(), false);
            alert.setOrigin(AlertOrigin.AUTOMATICO);
            alert.setSensor(sensor);
            alert.setReadingId(reading.getId());
            return alertRepository.save(alert).getId();
        }

        Alert alert = open.get();
        if (severity == AlertSeverity.CRITICAL && alert.getSeverity() != AlertSeverity.CRITICAL) {
            alert.setSeverity(AlertSeverity.CRITICAL);
            alert.setTitle("Leitura crítica: " + label);
            alert.setDescription(truncate(alert.getDescription() + " | Escalonado para CRITICAL: " + valueText
                    + " em " + reading.getReadAt().format(DateTimeFormatter.ofPattern("dd/MM HH:mm")) + ".", 1000));
            alert.setReadingId(reading.getId());
        }
        return alert.getId();
    }

    @Override
    @Transactional
    public int generateDailyReport(LocalDate referenceDate) {
        if (referenceDate.isAfter(LocalDate.now())) {
            throw new BusinessException("Data de referencia nao pode estar no futuro: " + referenceDate.format(DATE));
        }
        LocalDateTime from = referenceDate.atStartOfDay();
        LocalDateTime to = from.plusDays(1);
        List<Sensor> sensors = sensorRepository.findAllByOrderByIdAsc();

        for (Sensor sensor : sensors) {
            List<SensorReading> readings =
                    readingRepository.findBySensorIdAndReadAtGreaterThanEqualAndReadAtLessThan(sensor.getId(), from, to);
            DailyReport report = reportRepository.findBySensorIdAndReferenceDate(sensor.getId(), referenceDate)
                    .orElseGet(() -> new DailyReport(sensor, referenceDate));

            if (readings.isEmpty()) {
                report.update(0, 0, 0, null, null, null, null,
                        sensor.getName() + ": sem leituras em " + referenceDate.format(DATE) + ".");
            } else {
                DoubleSummaryStatistics stats = readings.stream().mapToDouble(SensorReading::getValue).summaryStatistics();
                long alerts = count(readings, ReadingClassification.ALERTA);
                long critical = count(readings, ReadingClassification.CRITICA);
                Double conformity = conformity(readings);
                double avg = round2(stats.getAverage());
                report.update(readings.size(), alerts, critical, stats.getMin(), avg, stats.getMax(), conformity,
                        truncate(sensor.getName() + " (" + sensor.getType() + "): " + readings.size()
                                + " leituras, média " + fmt(avg) + " " + sensor.getUnit()
                                + ", máx " + fmt(stats.getMax()) + " " + sensor.getUnit()
                                + ", " + critical + " críticas, conformidade " + fmt(conformity) + "%.", 400));
            }
            reportRepository.save(report);
        }
        log("PRC_GERAR_RELATORIO_DIARIO", "INFO", "Relatorio de " + referenceDate.format(DATE)
                + " gerado para " + sensors.size() + " sensores.");
        return sensors.size();
    }

    @Override
    @Transactional
    public int markInactiveSensors(int toleranceMinutes) {
        if (toleranceMinutes <= 0) {
            throw new BusinessException("Tolerancia deve ser maior que zero (minutos).");
        }
        List<Sensor> inactive = sensorRepository.findByStatusNotAndUpdatedAtBefore(
                SensorStatus.OFFLINE, LocalDateTime.now().minusMinutes(toleranceMinutes));

        for (Sensor sensor : inactive) {
            sensor.setStatus(SensorStatus.OFFLINE);
            if (!alertRepository.existsBySensorIdAndResolvedFalseAndTitleStartingWith(sensor.getId(), OFFLINE_ALERT_PREFIX)) {
                Alert alert = new Alert(OFFLINE_ALERT_PREFIX + sensor.getName(),
                        "Última leitura em " + sensor.getUpdatedAt().format(DATE_TIME)
                                + " (tolerância de " + toleranceMinutes + " min excedida).",
                        AlertSeverity.HIGH, sensor.getLocation(), LocalDateTime.now(), false);
                alert.setOrigin(AlertOrigin.AUTOMATICO);
                alert.setSensor(sensor);
                alertRepository.save(alert);
            }
        }
        log("PRC_VERIFICAR_SENSORES_INATIVOS", "INFO", inactive.size()
                + " sensor(es) marcados como OFFLINE (tolerancia " + toleranceMinutes + " min).");
        return inactive.size();
    }

    @Override
    @Transactional(readOnly = true)
    public SensorIndicators indicators(Long sensorId, int windowHours) {
        Sensor sensor = sensorRepository.findById(sensorId)
                .orElseThrow(() -> new NotFoundException("Sensor não encontrado: " + sensorId));
        return new SensorIndicators(sensorId,
                conformity(sensorId, windowHours),
                conformity(sensorId, 24 * 7),
                riskIndex(sensor.getLocation()),
                formatLastReading(sensor),
                ENGINE);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ResponsibleSummary> summaryByResponsible(int windowHours) {
        if (windowHours <= 0) {
            throw new BusinessException("Janela de tempo deve ser maior que zero (horas).");
        }
        LocalDateTime from = LocalDateTime.now().minusHours(windowHours);
        return userRepository.findAll().stream()
                .map(user -> summaryOf(user, from, windowHours))
                .sorted(Comparator.comparingLong(ResponsibleSummary::openAlerts).reversed()
                        .thenComparing(Comparator.comparingLong(ResponsibleSummary::sensors).reversed())
                        .thenComparing(ResponsibleSummary::name))
                .toList();
    }

    @Override
    public String engine() {
        return ENGINE;
    }

    private ResponsibleSummary summaryOf(User user, LocalDateTime from, int windowHours) {
        List<Sensor> sensors = sensorRepository.findByResponsibleId(user.getId());
        Double avgConformity = sensors.stream()
                .map(s -> conformity(s.getId(), windowHours))
                .filter(Objects::nonNull)
                .mapToDouble(Double::doubleValue)
                .average()
                .stream().map(JpaAnalyticsGateway::round2).boxed().findFirst().orElse(null);
        return new ResponsibleSummary(
                user.getId(), user.getName(), user.getRole().name(),
                sensors.size(),
                sensors.stream().filter(s -> s.getStatus() != SensorStatus.ONLINE).count(),
                readingRepository.countBySensorResponsibleIdAndReadAtGreaterThanEqual(user.getId(), from),
                readingRepository.countBySensorResponsibleIdAndClassificationAndReadAtGreaterThanEqual(
                        user.getId(), ReadingClassification.CRITICA, from),
                alertRepository.countBySensorResponsibleIdAndResolvedFalse(user.getId()),
                avgConformity);
    }

    /** Espelho de FN_CALC_CONFORMIDADE. */
    private Double conformity(Long sensorId, int windowHours) {
        LocalDateTime now = LocalDateTime.now();
        return conformity(readingRepository.findBySensorIdAndReadAtGreaterThanEqualAndReadAtLessThan(
                sensorId, now.minusHours(windowHours), now));
    }

    private static Double conformity(List<SensorReading> readings) {
        if (readings.isEmpty()) {
            return null;
        }
        return round2(count(readings, ReadingClassification.NORMAL) * 100.0 / readings.size());
    }

    /** Espelho de FN_CALC_INDICE_RISCO (pesos idênticos aos do PL/SQL). */
    private int riskIndex(String location) {
        String key = location.trim().toUpperCase(PT_BR);
        int alertPoints = alertRepository.findByResolvedFalse().stream()
                .filter(a -> a.getLocation().trim().toUpperCase(PT_BR).equals(key))
                .mapToInt(a -> switch (a.getSeverity()) {
                    case CRITICAL -> 40;
                    case HIGH -> 25;
                    case MEDIUM -> 10;
                    case LOW -> 5;
                })
                .sum();
        int sensorPoints = sensorRepository.findAll().stream()
                .filter(s -> s.getLocation().trim().toUpperCase(PT_BR).equals(key))
                .mapToInt(s -> switch (s.getStatus()) {
                    case WARNING -> 10;
                    case OFFLINE -> 15;
                    case ONLINE -> 0;
                })
                .sum();
        return Math.min(100, alertPoints + sensorPoints);
    }

    /** Espelho de FN_FORMATAR_LEITURA. */
    private String formatLastReading(Sensor sensor) {
        String label = sensor.getName() + " (" + sensor.getType() + ")";
        return readingRepository.findBySensorIdOrderByReadAtDescIdDesc(
                        sensor.getId(), org.springframework.data.domain.PageRequest.of(0, 1))
                .stream().findFirst()
                .map(r -> label + " | " + fmt(r.getValue())
                        + (sensor.getUnit() != null ? " " + sensor.getUnit() : "")
                        + " | " + r.getClassification() + " | " + r.getReadAt().format(DATE_TIME))
                .orElse(label + " | sem leituras registradas");
    }

    private void log(String routine, String level, String message) {
        logRepository.save(new ExecutionLog(routine, level, message));
    }

    private static long count(List<SensorReading> readings, ReadingClassification classification) {
        return readings.stream().filter(r -> r.getClassification() == classification).count();
    }

    private static double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    private static String fmt(Double value) {
        return value == null ? "-" : String.format(PT_BR, "%,.2f", value);
    }

    private static String truncate(String text, int max) {
        return text.length() <= max ? text : text.substring(0, max);
    }
}
