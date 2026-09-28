package br.com.smarthas.repository;

import br.com.smarthas.model.ExecutionLog;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ExecutionLogRepository extends JpaRepository<ExecutionLog, Long> {

    List<ExecutionLog> findAllByOrderByIdDesc(Pageable pageable);
}
