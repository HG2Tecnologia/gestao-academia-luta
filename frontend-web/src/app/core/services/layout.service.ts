import { Injectable, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class LayoutService {
  readonly sidebarAberta = signal(false);
  toggleSidebar(): void { this.sidebarAberta.update(v => !v); }
  fecharSidebar(): void { this.sidebarAberta.set(false); }
}
