import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Sensor } from '../models/models';

@Injectable({ providedIn: 'root' })
export class SensorService {
  private readonly baseUrl = `${environment.apiUrl}/sensors`;

  constructor(private readonly http: HttpClient) {}

  getSensors(): Observable<Sensor[]> {
    return this.http.get<Sensor[]>(this.baseUrl);
  }

  getSensor(id: number): Observable<Sensor> {
    return this.http.get<Sensor>(`${this.baseUrl}/${id}`);
  }
}
