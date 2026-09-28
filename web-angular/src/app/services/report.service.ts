import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import {
  DailyReportRow,
  ExecutionLog,
  ResponsibleSummary,
  RoutineResult,
} from '../models/models';

/** Relatórios consolidados e rotinas batch (procedures) do Smart HAS. */
@Injectable({ providedIn: 'root' })
export class ReportService {
  private readonly reportsUrl = `${environment.apiUrl}/reports`;
  private readonly routinesUrl = `${environment.apiUrl}/routines`;

  constructor(private readonly http: HttpClient) {}

  getDailyReport(date: string): Observable<DailyReportRow[]> {
    return this.http.get<DailyReportRow[]>(`${this.reportsUrl}/daily`, {
      params: new HttpParams().set('date', date),
    });
  }

  getResponsibles(hours = 24): Observable<ResponsibleSummary[]> {
    return this.http.get<ResponsibleSummary[]>(`${this.reportsUrl}/responsibles`, {
      params: new HttpParams().set('hours', hours),
    });
  }

  getLogs(limit = 15): Observable<ExecutionLog[]> {
    return this.http.get<ExecutionLog[]>(`${this.reportsUrl}/logs`, {
      params: new HttpParams().set('limit', limit),
    });
  }

  /** PRC_GERAR_RELATORIO_DIARIO (ADMIN). */
  generateDailyReport(date: string): Observable<RoutineResult> {
    return this.http.post<RoutineResult>(`${this.routinesUrl}/daily-report`, null, {
      params: new HttpParams().set('date', date),
    });
  }

  /** PRC_VERIFICAR_SENSORES_INATIVOS (ADMIN). */
  checkInactiveSensors(toleranceMinutes = 60): Observable<RoutineResult> {
    return this.http.post<RoutineResult>(`${this.routinesUrl}/inactive-sensors`, null, {
      params: new HttpParams().set('toleranceMinutes', toleranceMinutes),
    });
  }
}
