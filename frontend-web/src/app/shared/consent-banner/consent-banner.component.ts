import { Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ConsentService } from '../../core/services/consent.service';

@Component({
  selector: 'app-consent-banner',
  standalone: true,
  imports: [RouterLink],
  templateUrl: './consent-banner.component.html',
  styleUrls: ['./consent-banner.component.css'],
})
export class ConsentBannerComponent {
  readonly consent = inject(ConsentService);

  readonly personalizarAberto = signal(false);
  readonly analyticsMarcado = signal(true);
  readonly adsMarcado = signal(true);
  readonly personalizacaoMarcado = signal(true);

  aceitarTudo(): void {
    this.consent.aceitarTudo();
  }

  recusarTudo(): void {
    this.consent.recusarTudo();
  }

  abrirPersonalizar(): void {
    this.personalizarAberto.set(true);
  }

  confirmarPersonalizado(): void {
    this.consent.salvarPersonalizado({
      analytics: this.analyticsMarcado(),
      ads: this.adsMarcado(),
      personalization: this.personalizacaoMarcado(),
    });
    this.personalizarAberto.set(false);
  }
}
