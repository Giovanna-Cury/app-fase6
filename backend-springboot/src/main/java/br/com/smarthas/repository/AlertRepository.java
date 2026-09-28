package br.com.smarthas.repository;

import br.com.smarthas.model.Alert;
import br.com.smarthas.model.AlertOrigin;
import br.com.smarthas.model.AlertSeverity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AlertRepository extends JpaRepository<Alert, Long> {

    long countByResolvedFalse();

    long countByResolvedFalseAndSeverity(AlertSeverity severity);

    List<Alert> findAllByOrderByCreatedAtDesc();

    List<Alert> findByResolvedFalse();

    Optional<Alert> findFirstBySensorIdAndResolvedFalseAndOriginOrderByCreatedAtDesc(Long sensorId, AlertOrigin origin);

    boolean existsBySensorIdAndResolvedFalseAndTitleStartingWith(Long sensorId, String titlePrefix);

    long countBySensorResponsibleIdAndResolvedFalse(Long responsibleId);
}
