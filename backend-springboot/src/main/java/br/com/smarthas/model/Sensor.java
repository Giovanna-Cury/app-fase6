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

@Entity
@Table(name = "shas_sensor")
public class Sensor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_sensor")
    private Long id;

    @Column(name = "nome", nullable = false, length = 100)
    private String name;

    @Column(name = "tipo", nullable = false, length = 50)
    private String type;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private SensorStatus status;

    @Column(name = "localizacao", nullable = false, length = 150)
    private String location;

    @JdbcTypeCode(SqlTypes.NUMERIC)
    @Column(name = "valor_atual", precision = 12, scale = 2)
    private Double value;

    @Column(name = "unidade", length = 20)
    private String unit;

    @JdbcTypeCode(SqlTypes.NUMERIC)
    @Column(name = "latitude", precision = 9, scale = 6)
    private Double latitude;

    @JdbcTypeCode(SqlTypes.NUMERIC)
    @Column(name = "longitude", precision = 9, scale = 6)
    private Double longitude;

    /** Limite a partir do qual a leitura é ALERTA (regra de FN_CLASSIFICAR_LEITURA). */
    @JdbcTypeCode(SqlTypes.NUMERIC)
    @Column(name = "limite_alerta", precision = 12, scale = 2)
    private Double alertThreshold;

    /** Limite a partir do qual a leitura é CRITICA. */
    @JdbcTypeCode(SqlTypes.NUMERIC)
    @Column(name = "limite_critico", precision = 12, scale = 2)
    private Double criticalThreshold;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_responsavel")
    private User responsible;

    @Column(name = "dt_atualizacao", nullable = false)
    private LocalDateTime updatedAt;

    public Sensor() {
    }

    public Sensor(String name, String type, SensorStatus status, String location,
                  Double value, String unit, Double latitude, Double longitude,
                  LocalDateTime updatedAt) {
        this.name = name;
        this.type = type;
        this.status = status;
        this.location = location;
        this.value = value;
        this.unit = unit;
        this.latitude = latitude;
        this.longitude = longitude;
        this.updatedAt = updatedAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public SensorStatus getStatus() {
        return status;
    }

    public void setStatus(SensorStatus status) {
        this.status = status;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public Double getValue() {
        return value;
    }

    public void setValue(Double value) {
        this.value = value;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public Double getAlertThreshold() {
        return alertThreshold;
    }

    public void setAlertThreshold(Double alertThreshold) {
        this.alertThreshold = alertThreshold;
    }

    public Double getCriticalThreshold() {
        return criticalThreshold;
    }

    public void setCriticalThreshold(Double criticalThreshold) {
        this.criticalThreshold = criticalThreshold;
    }

    public User getResponsible() {
        return responsible;
    }

    public void setResponsible(User responsible) {
        this.responsible = responsible;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
