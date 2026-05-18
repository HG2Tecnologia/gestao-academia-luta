import { HttpInterceptorFn, HttpErrorResponse } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, switchMap, throwError } from 'rxjs';
import { AuthService } from '../services/auth.service';

const AUTH_ENDPOINTS = ['/api/auth/login', '/api/auth/register', '/api/auth/refresh', '/api/auth/logout'];

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const authService = inject(AuthService);
  const router = inject(Router);

  const token = authService.getAccessToken();
  const reqAutenticada = token
    ? req.clone({ setHeaders: { Authorization: `Bearer ${token}` } })
    : req;

  return next(reqAutenticada).pipe(
    catchError((erro: unknown) => {
      const isAuthEndpoint = AUTH_ENDPOINTS.some((e) => req.url.includes(e));
      if (erro instanceof HttpErrorResponse && erro.status === 401 && !isAuthEndpoint) {
        return authService.refreshToken().pipe(
          switchMap((res) => {
            if (res.sucesso && res.dados) {
              const novaReq = req.clone({
                setHeaders: { Authorization: `Bearer ${res.dados.accessToken}` },
              });
              return next(novaReq);
            }
            authService.logout();
            router.navigate(['/login']);
            return throwError(() => erro);
          }),
          catchError(() => {
            authService.logout();
            router.navigate(['/login']);
            return throwError(() => erro);
          })
        );
      }
      return throwError(() => erro);
    })
  );
};
