import { Component, effect, inject } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { SeoService } from './core/services/seo.service';
import { ConsentService } from './core/services/consent.service';
import { AttributionService } from './core/services/attribution.service';
import { AnalyticsService } from './core/services/analytics.service';
import { ConsentBannerComponent } from './shared/consent-banner/consent-banner.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, ConsentBannerComponent],
  template: '<router-outlet /><app-consent-banner />',
})
export class AppComponent {
  constructor() {
    inject(SeoService).iniciar();

    const consent = inject(ConsentService);
    const attribution = inject(AttributionService);
    const analytics = inject(AnalyticsService);

    // Ordem importa: consent default precisa estar no dataLayer antes do
    // gtag.js carregar (AnalyticsService.iniciar()), e a atribuição lê o
    // estado de consentimento atual antes de decidir se persiste.
    consent.iniciar();
    attribution.capturarNaChegada();
    analytics.iniciar();

    // Se o usuário aceitar análise depois de já ter chegado com UTM/gclid
    // (banner respondido alguns segundos após o carregamento), a
    // atribuição real da visita ainda é salva — não se perde por só ter
    // sido classificada antes do consentimento existir.
    effect(() => {
      if (consent.estado().analytics_storage === 'granted') {
        attribution.persistirAposConsentimento();
      }
    });
  }
}
