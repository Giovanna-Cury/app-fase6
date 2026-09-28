import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AlertService } from '../../services/alert.service';
import { Alert, CreateAlertPayload, Severity } from '../../models/models';

@Component({
  selector: 'app-admin',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './admin.component.html',
  styleUrl: './admin.component.css',
})
export class AdminComponent implements OnInit {
  alerts: Alert[] = [];
  loading = false;
  error = '';

  // Feedback do formulário.
  submitting = false;
  successMsg = '';
  formError = '';

  severities: Severity[] = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

  // Modelo do formulário ligado por [(ngModel)].
  form: CreateAlertPayload = {
    title: '',
    description: '',
    location: '',
    severity: 'MEDIUM',
  };

  constructor(private readonly alertService: AlertService) {}

  ngOnInit(): void {
    this.load();
  }

  load(): void {
    this.loading = true;
    this.error = '';
    this.alertService.getAlerts().subscribe({
      next: (data) => {
        this.alerts = data;
        this.loading = false;
      },
      error: (err) => {
        this.loading = false;
        this.error = err?.error?.message ?? 'Não foi possível carregar os alertas.';
      },
    });
  }

  createAlert(): void {
    this.successMsg = '';
    this.formError = '';

    if (!this.form.title || !this.form.location || !this.form.severity) {
      this.formError = 'Preencha título, localização e severidade.';
      return;
    }

    this.submitting = true;
    this.alertService.createAlert({ ...this.form }).subscribe({
      next: () => {
        this.submitting = false;
        this.successMsg = 'Alerta criado com sucesso.';
        this.resetForm();
        this.load();
      },
      error: (err) => {
        this.submitting = false;
        this.formError = err?.error?.message ?? 'Falha ao criar o alerta.';
      },
    });
  }

  resolve(id: number): void {
    this.successMsg = '';
    this.formError = '';
    this.alertService.resolve(id).subscribe({
      next: () => {
        this.successMsg = 'Alerta resolvido.';
        this.load();
      },
      error: (err) => {
        this.error = err?.error?.message ?? 'Falha ao resolver o alerta.';
      },
    });
  }

  private resetForm(): void {
    this.form = { title: '', description: '', location: '', severity: 'MEDIUM' };
  }
}
