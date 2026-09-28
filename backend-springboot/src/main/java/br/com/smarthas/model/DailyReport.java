package br.com.smarthas.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDate;
import java.time.LocalDateTime;

/** Consolidado diário por sensor, gerado por PRC_GERAR_RELATORIO_DIARIO. */
@Entity
@Table(name = "shas_relatorio_diario",
        uniqueConstraints = @UniqueConstraint(columnNames = {"id_sensor", "dt_referencia"}))
public class DailyReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_relatorio")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_sensor", nullable = false)
    private Sensor sensor;

    @Column(name = "dt_referencia", nullable = false)
    private LocalDate referenceDate;

    @Column(name = "qtd_leituras", nullable = false)
    private long readings;

    @Column(name = "qtd_alertas", nullable = false)
    private long alertReadings;

    @Column(name = "qtd_criticas", nullable = false)
    private long criticalReadings;

    @JdbcTypeCode(SqlTypes.NUMERIC)
    @Column(name = "valor_minimo", precision = 12, scale = 2)
    private Double minValue;

    @JdbcTypeCode(SqlTypes.NUMERIC)
    @Column(name = "valor_medio", precision = 12, scale = 2)
    private Double avgValue;

    @JdbcTypeCode(SqlTypes.NUMERIC)
    @Column(name = "valor_maximo", precision = 12, scale = 2)
    private Double maxValue;

    @JdbcTypeCode(SqlTypes.NUMERIC)
    @Column(name = "conformidade", precision = 5, scale = 2)
    private Double conformity;

    @Column(name = "resumo", length = 400)
    private String summary;

    @Column(name = "dt_geracao", nullable = false)
    private LocalDateTime generatedAt;

    public DailyReport() {
    }

    public DailyReport(Sensor sensor, LocalDate referenceDate) {
        this.sensor = sensor;
        this.referenceDate = referenceDate;
    }

    public void update(long readings, long alertReadings, long criticalReadings,
                       Double minValue, Double avgValue, Double maxValue,
                       Double conformity, String summary) {
        this.readings = readings;
        this.alertReadings = alertReadings;
        this.criticalReadings = criticalReadings;
        this.minValue = minValue;
        this.avgValue = avgValue;
        this.maxValue = maxValue;
        this.conformity = conformity;
        this.summary = summary;
        this.generatedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public Sensor getSensor() {
        return sensor;
    }

    public LocalDate getReferenceDate() {
        return referenceDate;
    }

    public long getReadings() {
        return readings;
    }

    public long getAlertReadings() {
        return alertReadings;
    }

    public long getCriticalReadings() {
        return criticalReadings;
    }

    public Double getMinValue() {
        return minValue;
    }

    public Double getAvgValue() {
        return avgValue;
    }

    public Double getMaxValue() {
        return maxValue;
    }

    public Double getConformity() {
        return conformity;
    }

    public String getSummary() {
        return summary;
    }

    public LocalDateTime getGeneratedAt() {
        return generatedAt;
    }
}
