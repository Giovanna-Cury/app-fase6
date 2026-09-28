import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';
import { SensorService } from '../../services/sensor.service';
import { TelemetryService } from '../../services/telemetry.service';
import {
  ReadingRegistration,
  Sensor,
  SensorIndicators,
  SensorReading,
} from '../../models/models';

interface ChartLine {
  y: number;
  kind: 'alert' | 'critical';
}

/** Área útil do gráfico de histórico (coordenadas do viewBox do SVG). */
const CHART = { width: 640, height: 160, padding: 12 };

@Component({
  selector: 'app-sensor-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './sensor-detail.component.html',
  styleUrl: './sensor-detail.component.css',
})
export class SensorDetailComponent implements OnInit {
  readonly chart = CHART;

  sensorId = 0;
  sensor: Sensor | null = null;
  indicators: SensorIndicators | null = null;
  readings: SensorReading[] = [];

  loading = false;
  error = '';

  // Formulário "Registrar leitura" — [(ngModel)]
  newValue: number | null = null;
  submitting = false;
  lastResult: ReadingRegistration | null = null;
  formError = '';

  // Geometria do gráfico, recalculada a cada carga.
  chartPoints = '';
  chartThresholds: ChartLine[] = [];

  constructor(
    private readonly route: ActivatedRoute,
    private readonly sensorService: SensorService,
    private readonly telemetry: TelemetryService,
  ) {}

  ngOnInit(): void {
    this.sensorId = Number(this.route.snapshot.paramMap.get('id'));
    this.load();
  }

  load(): void {
    this.loading = true;
    this.error = '';
    forkJoin({
      sensor: this.sensorService.getSensor(this.sensorId),
      indicators: this.telemetry.getIndicators(this.sensorId),
      readings: this.telemetry.getReadings(this.sensorId, 48),
    }).subscribe({
      next: ({ sensor, indicators, readings }) => {
        this.sensor = sensor;
        this.indicators = indicators;
        this.readings = readings;
        this.buildChart();
        this.loading = false;
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.message ?? 'Não foi possível carregar o sensor.';
      },
    });
  }

  registerReading(): void {
    this.formError = '';
    this.lastResult = null;
    if (this.newValue === null || Number.isNaN(Number(this.newValue))) {
      this.formError = 'Informe o valor medido.';
      return;
    }

    this.submitting = true;
    this.telemetry.registerReading(this.sensorId, Number(this.newValue)).subscribe({
      next: (result) => {
        this.submitting = false;
        this.lastResult = result;
        this.newValue = null;
        this.load();
      },
      error: (err) => {
        this.submitting = false;
        // Mensagens de negócio vêm do PL/SQL (RAISE_APPLICATION_ERROR → HTTP 404/422).
        this.formError = err?.error?.message ?? 'Falha ao registrar a leitura.';
      },
    });
  }

  riskLevel(index: number): string {
    if (index >= 50) return 'Alto';
    if (index >= 20) return 'Moderado';
    return 'Baixo';
  }

  /** Série do mais antigo para o mais recente + linhas dos limites do sensor. */
  private buildChart(): void {
    const series = [...this.readings].reverse();
    const limits = [this.sensor?.alertThreshold, this.sensor?.criticalThreshold].filter(
      (v): v is number => v !== null && v !== undefined,
    );
    if (series.length < 2) {
      this.chartPoints = '';
      this.chartThresholds = [];
      return;
    }

    const values = series.map((r) => r.value);
    const min = Math.min(...values, ...limits);
    const max = Math.max(...values, ...limits);
    const span = max - min || 1;
    const { width, height, padding } = CHART;
    const y = (v: number) => padding + (1 - (v - min) / span) * (height - 2 * padding);
    const x = (i: number) => padding + (i / (series.length - 1)) * (width - 2 * padding);

    this.chartPoints = series.map((r, i) => `${x(i).toFixed(1)},${y(r.value).toFixed(1)}`).join(' ');
    this.chartThresholds = [
      ...(this.sensor?.alertThreshold != null
        ? [{ y: y(this.sensor.alertThreshold), kind: 'alert' as const }]
        : []),
      ...(this.sensor?.criticalThreshold != null
        ? [{ y: y(this.sensor.criticalThreshold), kind: 'critical' as const }]
        : []),
    ];
  }
}
