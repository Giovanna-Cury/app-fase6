package br.com.smarthas.repository;

import br.com.smarthas.model.DailyReport;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface DailyReportRepository extends JpaRepository<DailyReport, Long> {

    Optional<DailyReport> findBySensorIdAndReferenceDate(Long sensorId, LocalDate referenceDate);

    @EntityGraph(attributePaths = "sensor")
    List<DailyReport> findByReferenceDateOrderBySensorIdAsc(LocalDate referenceDate);
}
