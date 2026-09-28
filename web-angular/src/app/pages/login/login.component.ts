import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.css',
})
export class LoginComponent {
  // Campos ligados via two-way binding [(ngModel)].
  username = '';
  password = '';

  loading = false;
  error = '';

  constructor(
    private readonly auth: AuthService,
    private readonly router: Router,
  ) {}

  onSubmit(): void {
    this.error = '';

    if (!this.username || !this.password) {
      this.error = 'Informe usuário e senha.';
      return;
    }

    this.loading = true;
    this.auth.login(this.username, this.password).subscribe({
      next: () => {
        this.loading = false;
        this.router.navigate(['/home']);
      },
      error: (err) => {
        this.loading = false;
        if (err?.status === 0) {
          // status 0 = não conseguiu alcançar a API (offline/CORS), não é senha errada.
          this.error =
            'Não foi possível conectar à API. Verifique se o back-end está '
            + 'rodando em http://localhost:8080.';
        } else if (err?.status === 401) {
          this.error = err?.error?.message ?? 'Usuário ou senha inválidos.';
        } else {
          this.error = err?.error?.message ?? 'Falha ao autenticar. Tente novamente.';
        }
      },
    });
  }
}
