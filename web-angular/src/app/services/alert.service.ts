import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Alert, CreateAlertPayload } from '../models/models';

@Injectable({ providedIn: 'root' })
export class AlertService {
  private readonly baseUrl = `${environment.apiUrl}/alerts`;

  constructor(private readonly http: HttpClient) {}

  getAlerts(): Observable<Alert[]> {
    return this.http.get<Alert[]>(this.baseUrl);
  }

  getAlert(id: number): Observable<Alert> {
    return this.http.get<Alert>(`${this.baseUrl}/${id}`);
  }

  createAlert(payload: CreateAlertPayload): Observable<Alert> {
    return this.http.post<Alert>(this.baseUrl, payload);
  }

  resolve(id: number): Observable<Alert> {
    return this.http.put<Alert>(`${this.baseUrl}/${id}/resolve`, {});
  }
}
