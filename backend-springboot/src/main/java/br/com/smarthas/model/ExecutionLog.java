package br.com.smarthas.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** Trilha de auditoria das rotinas (SHAS_LOG_EXECUCAO). */
@Entity
@Table(name = "shas_log_execucao")
public class ExecutionLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_log")
    private Long id;

    @Column(name = "rotina", nullable = false, length = 60)
    private String routine;

    @Column(name = "nivel", nullable = false, length = 10)
    private String level;

    @Column(name = "mensagem", length = 4000)
    private String message;

    @Column(name = "dt_log", nullable = false)
    private LocalDateTime loggedAt;

    public ExecutionLog() {
    }

    public ExecutionLog(String routine, String level, String message) {
        this.routine = routine;
        this.level = level;
        this.message = message;
        this.loggedAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public String getRoutine() {
        return routine;
    }

    public String getLevel() {
        return level;
    }

    public String getMessage() {
        return message;
    }

    public LocalDateTime getLoggedAt() {
        return loggedAt;
    }
}
