package br.com.smarthas.dto;

import br.com.smarthas.model.DailyReport;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record DailyReportDto(
        Long sensorId,
        String sensorName,
        String sensorType,
        String unit,
        LocalDate referenceDate,
        long readings,
        long alertReadings,
        long criticalReadings,
        Double minValue,
        Double avgValue,
        Double maxValue,
        Double conformity,
        String summary,
        LocalDateTime generatedAt
) {
    public static DailyReportDto from(DailyReport report) {
        var sensor = report.getSensor();
        return new DailyReportDto(
                sensor.getId(),
                sensor.getName(),
                sensor.getType(),
                sensor.getUnit(),
                report.getReferenceDate(),
                report.getReadings(),
                report.getAlertReadings(),
                report.getCriticalReadings(),
                report.getMinValue(),
                report.getAvgValue(),
                report.getMaxValue(),
                report.getConformity(),
                report.getSummary(),
                report.getGeneratedAt()
        );
    }
}
