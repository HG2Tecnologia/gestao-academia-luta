import { Injectable } from '@angular/core';
import { environment } from '../../../environments/environment';

const STORAGE_KEY = 'af_tenant_id';

@Injectable({ providedIn: 'root' })
export class TenantService {
  private readonly _tenantId: string;

  constructor() {
    this._tenantId = this.resolverTenant();
  }

  get tenantId(): string {
    return this._tenantId;
  }

  private resolverTenant(): string {
    const hostname = window.location.hostname;

    // Em produção, o subdomínio é parte do hostname: academia.suaplataforma.com
    const partes = hostname.split('.');
    if (partes.length >= 3) {
      return partes[0];
    }

    // Em desenvolvimento, usar valor do localStorage ou fallback
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) return stored;

    return environment.tenantFallback;
  }

  definirTenantDev(tenantId: string): void {
    localStorage.setItem(STORAGE_KEY, tenantId);
  }
}
