import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { forkJoin } from 'rxjs';
import { SensorService } from '../../services/sensor.service';
import { DashboardService } from '../../services/dashboard.service';
import { DashboardSummary, Sensor } from '../../models/models';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './home.component.html',
  styleUrl: './home.component.css',
})
export class HomeComponent implements OnInit {
  sensors: Sensor[] = [];
  summary: DashboardSummary | null = null;
  loading = false;
  error = '';

  constructor(
    private readonly sensorService: SensorService,
    private readonly dashboardService: DashboardService,
    private readonly router: Router,
  ) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.error = '';
    // KPIs agora vêm do back-end (consultas no banco), não de contas no front.
    forkJoin({
      sensors: this.sensorService.getSensors(),
      summary: this.dashboardService.getSummary(),
    }).subscribe({
      next: ({ sensors, summary }) => {
        this.sensors = sensors;
        this.summary = summary;
        this.loading = false;
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.message ?? 'Não foi possível carregar os sensores.';
      },
    });
  }

  openSensor(sensor: Sensor): void {
    this.router.navigate(['/sensors', sensor.id]);
  }
}
