import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { ReadingRegistration, SensorIndicators, SensorReading } from '../models/models';

/** Leituras e indicadores de um sensor (rotinas PL/SQL expostas pela API). */
@Injectable({ providedIn: 'root' })
export class TelemetryService {
  private readonly baseUrl = `${environment.apiUrl}/sensors`;

  constructor(private readonly http: HttpClient) {}

  /** Dispara PRC_REGISTRAR_LEITURA no back-end (REST → Java → JDBC → Oracle). */
  registerReading(sensorId: number, value: number): Observable<ReadingRegistration> {
    return this.http.post<ReadingRegistration>(`${this.baseUrl}/${sensorId}/readings`, { value });
  }

  getReadings(sensorId: number, limit = 48): Observable<SensorReading[]> {
    const params = new HttpParams().set('limit', limit);
    return this.http.get<SensorReading[]>(`${this.baseUrl}/${sensorId}/readings`, { params });
  }

  getIndicators(sensorId: number): Observable<SensorIndicators> {
    return this.http.get<SensorIndicators>(`${this.baseUrl}/${sensorId}/indicators`);
  }
}
