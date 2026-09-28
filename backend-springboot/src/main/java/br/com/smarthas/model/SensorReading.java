package br.com.smarthas.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;

/** Uma medição do histórico de telemetria (SHAS_LEITURA). */
@Entity
@Table(name = "shas_leitura")
public class SensorReading {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_leitura")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_sensor", nullable = false)
    private Sensor sensor;

    @JdbcTypeCode(SqlTypes.NUMERIC)
    @Column(name = "valor", nullable = false, precision = 12, scale = 2)
    private Double value;

    @Enumerated(EnumType.STRING)
    @Column(name = "classificacao", nullable = false, length = 10)
    private ReadingClassification classification;

    @Column(name = "dt_leitura", nullable = false)
    private LocalDateTime readAt;

    public SensorReading() {
    }

    public SensorReading(Sensor sensor, Double value, ReadingClassification classification, LocalDateTime readAt) {
        this.sensor = sensor;
        this.value = value;
        this.classification = classification;
        this.readAt = readAt;
    }

    public Long getId() {
        return id;
    }

    public Sensor getSensor() {
        return sensor;
    }

    public Double getValue() {
        return value;
    }

    public ReadingClassification getClassification() {
        return classification;
    }

    public LocalDateTime getReadAt() {
        return readAt;
    }
}
