package br.com.smarthas.repository;

import br.com.smarthas.model.ReadingClassification;
import br.com.smarthas.model.SensorReading;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface SensorReadingRepository extends JpaRepository<SensorReading, Long> {

    List<SensorReading> findBySensorIdOrderByReadAtDescIdDesc(Long sensorId, Pageable pageable);

    List<SensorReading> findBySensorIdAndReadAtGreaterThanEqualAndReadAtLessThan(
            Long sensorId, LocalDateTime from, LocalDateTime to);

    long countByReadAtGreaterThanEqual(LocalDateTime from);

    long countBySensorResponsibleIdAndReadAtGreaterThanEqual(Long responsibleId, LocalDateTime from);

    long countBySensorResponsibleIdAndClassificationAndReadAtGreaterThanEqual(
            Long responsibleId, ReadingClassification classification, LocalDateTime from);
}
