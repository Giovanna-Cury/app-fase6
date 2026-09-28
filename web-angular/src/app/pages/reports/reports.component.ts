import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ReportService } from '../../services/report.service';
import { AuthService } from '../../services/auth.service';
import {
  DailyReportRow,
  ExecutionLog,
  ResponsibleSummary,
  RoutineResult,
} from '../../models/models';

/** yyyy-MM-dd no fuso local (toISOString usaria UTC e poderia virar o dia). */
function today(): string {
  const d = new Date();
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

@Component({
  selector: 'app-reports',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './reports.component.html',
  styleUrl: './reports.component.css',
})
export class ReportsComponent implements OnInit {
  // Filtro do relatório diário — [(ngModel)]
  date = today();
  toleranceMinutes = 60;

  daily: DailyReportRow[] = [];
  responsibles: ResponsibleSummary[] = [];
  logs: ExecutionLog[] = [];

  loading = false;
  error = '';
  running = false;
  routineMsg = '';
  routineError = '';

  constructor(
    private readonly reports: ReportService,
    protected readonly auth: AuthService,
  ) {}

  get isAdmin(): boolean {
    return this.auth.currentUser()?.role === 'ADMIN';
  }

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.error = '';
    this.reports.getDailyReport(this.date).subscribe({
      next: (rows) => {
        this.daily = rows;
        this.loading = false;
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.message ?? 'Não foi possível carregar o relatório.';
      },
    });
    this.reports.getResponsibles(24).subscribe({ next: (rows) => (this.responsibles = rows) });
    if (this.isAdmin) {
      this.reports.getLogs(12).subscribe({ next: (rows) => (this.logs = rows) });
    }
  }

  generateReport(): void {
    this.runRoutine(this.reports.generateDailyReport(this.date), (r) =>
      `Relatório de ${this.date.split('-').reverse().join('/')} gerado para ${r.processed} sensores.`,
    );
  }

  checkInactive(): void {
    this.runRoutine(this.reports.checkInactiveSensors(this.toleranceMinutes), (r) =>
      `${r.processed} sensor(es) marcados como OFFLINE (tolerância ${this.toleranceMinutes} min).`,
    );
  }

  private runRoutine(
    call: ReturnType<ReportService['generateDailyReport']>,
    describe: (r: RoutineResult) => string,
  ): void {
    this.running = true;
    this.routineMsg = '';
    this.routineError = '';
    call.subscribe({
      next: (result) => {
        this.running = false;
        this.routineMsg = `${result.routine}: ${describe(result)}`;
        this.load();
      },
      error: (err) => {
        this.running = false;
        this.routineError = err?.error?.message ?? 'Falha ao executar a rotina.';
        this.load();
      },
    });
  }
}
