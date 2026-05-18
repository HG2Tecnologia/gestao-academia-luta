import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Router } from '@angular/router';
import { Observable, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import {
  LoginRequest,
  LoginResponse,
  RefreshTokenRequest,
  RegisterRequest,
  BaseResponse,
} from '../models/auth.model';
import { UserPayload } from '../models/user.model';

const ACCESS_TOKEN_KEY = 'af_access_token';
const REFRESH_TOKEN_KEY = 'af_refresh_token';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private readonly http = inject(HttpClient);
  private readonly router = inject(Router);
  private readonly apiUrl = `${environment.apiUrl}/api/auth`;

  readonly currentUser = signal<UserPayload | null>(this.getUser());

  register(request: RegisterRequest): Observable<BaseResponse<LoginResponse>> {
    return this.http.post<BaseResponse<LoginResponse>>(`${this.apiUrl}/register`, request).pipe(
      tap((res) => {
        if (res.sucesso && res.dados) {
          this.salvarTokens(res.dados.accessToken, res.dados.refreshToken);
          this.currentUser.set(this.getUser());
        }
      })
    );
  }

  login(request: LoginRequest): Observable<BaseResponse<LoginResponse>> {
    return this.http.post<BaseResponse<LoginResponse>>(`${this.apiUrl}/login`, request).pipe(
      tap((res) => {
        if (res.sucesso && res.dados) {
          this.salvarTokens(res.dados.accessToken, res.dados.refreshToken);
          this.currentUser.set(this.getUser());
        }
      })
    );
  }

  logout(): void {
    const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY);
    if (refreshToken) {
      this.http.post(`${this.apiUrl}/logout`, JSON.stringify(refreshToken), {
        headers: { 'Content-Type': 'application/json' },
      }).subscribe({ error: () => {} });
    }
    this.limparTokens();
    this.currentUser.set(null);
    this.router.navigate(['/login']);
  }

  alterarSenha(senhaAtual: string, novaSenha: string): Observable<BaseResponse<void>> {
    return this.http.post<BaseResponse<void>>(`${this.apiUrl}/alterar-senha`, { senhaAtual, novaSenha });
  }

  forgotPassword(email: string): Observable<BaseResponse<void>> {
    return this.http.post<BaseResponse<void>>(`${this.apiUrl}/forgot-password`, { email });
  }

  resetPassword(token: string, novaSenha: string): Observable<BaseResponse<void>> {
    return this.http.post<BaseResponse<void>>(`${this.apiUrl}/reset-password`, { token, novaSenha });
  }

  refreshToken(): Observable<BaseResponse<LoginResponse>> {
    const accessToken = localStorage.getItem(ACCESS_TOKEN_KEY) ?? '';
    const refreshToken = localStorage.getItem(REFRESH_TOKEN_KEY) ?? '';
    const payload: RefreshTokenRequest = { accessToken, refreshToken };

    return this.http.post<BaseResponse<LoginResponse>>(`${this.apiUrl}/refresh`, payload).pipe(
      tap((res) => {
        if (res.sucesso && res.dados) {
          this.salvarTokens(res.dados.accessToken, res.dados.refreshToken);
          this.currentUser.set(this.getUser());
        }
      })
    );
  }

  isAuthenticated(): boolean {
    const token = localStorage.getItem(ACCESS_TOKEN_KEY);
    if (!token) return false;

    const payload = this.decodificarToken(token);
    if (!payload) return false;

    // Verificar expiração (exp em segundos Unix)
    return payload.exp * 1000 > Date.now();
  }

  getUser(): UserPayload | null {
    const token = localStorage.getItem(ACCESS_TOKEN_KEY);
    if (!token) return null;
    return this.decodificarToken(token);
  }

  getAccessToken(): string | null {
    return localStorage.getItem(ACCESS_TOKEN_KEY);
  }

  getRefreshToken(): string | null {
    return localStorage.getItem(REFRESH_TOKEN_KEY);
  }

  private salvarTokens(accessToken: string, refreshToken: string): void {
    localStorage.setItem(ACCESS_TOKEN_KEY, accessToken);
    localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
  }

  private limparTokens(): void {
    localStorage.removeItem(ACCESS_TOKEN_KEY);
    localStorage.removeItem(REFRESH_TOKEN_KEY);
  }

  private decodificarToken(token: string): UserPayload | null {
    try {
      const partes = token.split('.');
      if (partes.length !== 3) return null;
      // base64url → base64 padrão
      const base64 = partes[1].replace(/-/g, '+').replace(/_/g, '/');
      const padded = base64.padEnd(base64.length + ((4 - (base64.length % 4)) % 4), '=');
      const raw = JSON.parse(atob(padded));
      if (typeof raw['permissoes'] === 'string') {
        try { raw['permissoes'] = JSON.parse(raw['permissoes']); } catch { raw['permissoes'] = {}; }
      }
      return raw as UserPayload;
    } catch {
      return null;
    }
  }
}
