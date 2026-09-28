package br.com.smarthas.repository;

import br.com.smarthas.model.Sensor;
import br.com.smarthas.model.SensorStatus;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface SensorRepository extends JpaRepository<Sensor, Long> {

    long countByStatus(SensorStatus status);

    @EntityGraph(attributePaths = "responsible")
    List<Sensor> findAllByOrderByIdAsc();

    List<Sensor> findByStatusNotAndUpdatedAtBefore(SensorStatus status, LocalDateTime limit);

    List<Sensor> findByResponsibleId(Long responsibleId);
}
