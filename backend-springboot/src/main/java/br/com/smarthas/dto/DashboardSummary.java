package br.com.smarthas.dto;

public record DashboardSummary(
        long totalSensors,
        long onlineSensors,
        long offlineSensors,
        long activeAlerts,
        long warningSensors,
        long criticalAlerts,
        long readingsLast24h,
        String dataEngine
) {
}
