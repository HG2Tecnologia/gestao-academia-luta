import { HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { TenantService } from '../services/tenant.service';

export const tenantInterceptor: HttpInterceptorFn = (req, next) => {
  const tenantService = inject(TenantService);
  const tenantId = tenantService.tenantId;

  if (!tenantId) return next(req);

  const reqComTenant = req.clone({
    setHeaders: { 'X-Tenant-ID': tenantId },
  });

  return next(reqComTenant);
};
