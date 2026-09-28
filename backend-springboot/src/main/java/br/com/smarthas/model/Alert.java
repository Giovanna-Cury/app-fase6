package br.com.smarthas.model;

import jakarta.persistence.Column;
import jakarta.persistence.Convert;
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
import org.hibernate.type.NumericBooleanConverter;

import java.time.LocalDateTime;

@Entity
@Table(name = "shas_alerta")
public class Alert {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_alerta")
    private Long id;

    @Column(name = "titulo", nullable = false, length = 150)
    private String title;

    @Column(name = "descricao", length = 1000)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "severidade", nullable = false, length = 10)
    private AlertSeverity severity;

    @Column(name = "localizacao", nullable = false, length = 150)
    private String location;

    @Enumerated(EnumType.STRING)
    @Column(name = "origem", nullable = false, length = 10)
    private AlertOrigin origin = AlertOrigin.MANUAL;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_sensor")
    private Sensor sensor;

    @Column(name = "id_leitura")
    private Long readingId;

    /** NUMBER(1) 0/1 no Oracle (sem BOOLEAN em tabela antes do 23ai). */
    @Convert(converter = NumericBooleanConverter.class)
    @Column(name = "resolvido", nullable = false)
    private boolean resolved;

    @Column(name = "dt_criacao", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "dt_resolucao")
    private LocalDateTime resolvedAt;

    public Alert() {
    }

    public Alert(String title, String description, AlertSeverity severity,
                 String location, LocalDateTime createdAt, boolean resolved) {
        this.title = title;
        this.description = description;
        this.severity = severity;
        this.location = location;
        this.createdAt = createdAt;
        this.resolved = resolved;
    }

    /** Marca como resolvido registrando o momento da resolução. */
    public void resolve() {
        if (!resolved) {
            resolved = true;
            resolvedAt = LocalDateTime.now();
        }
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public AlertSeverity getSeverity() {
        return severity;
    }

    public void setSeverity(AlertSeverity severity) {
        this.severity = severity;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public AlertOrigin getOrigin() {
        return origin;
    }

    public void setOrigin(AlertOrigin origin) {
        this.origin = origin;
    }

    public Sensor getSensor() {
        return sensor;
    }

    public void setSensor(Sensor sensor) {
        this.sensor = sensor;
    }

    public Long getReadingId() {
        return readingId;
    }

    public void setReadingId(Long readingId) {
        this.readingId = readingId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public boolean isResolved() {
        return resolved;
    }

    public LocalDateTime getResolvedAt() {
        return resolvedAt;
    }
}
