import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { AcessoWebService } from '../../core/services/acesso-web.service';
import { FirebaseAuthService } from '../../core/services/firebase-auth.service';

/**
 * Tela de quem entrou no web sem ter direito a ele. A assinatura é feita pelo
 * app; aqui só se explica o caminho.
 */
@Component({
  selector: 'app-assinatura',
  standalone: true,
  templateUrl: './assinatura.component.html',
  styleUrls: ['./assinatura.component.css'],
})
export class AssinaturaComponent implements OnInit {
  private readonly authService = inject(FirebaseAuthService);
  private readonly acessoService = inject(AcessoWebService);
  private readonly router = inject(Router);

  readonly verificando = signal(false);
  readonly aviso = signal('');

  /** Só Admin e Secretaria recebem as instruções de assinatura. */
  readonly podeAssinar = computed(() =>
    ['Admin', 'Secretaria'].includes(this.authService.currentUser()?.perfil ?? ''),
  );

  readonly situacao = computed(() => this.acessoService.acesso()?.situacao ?? 'gratis');

  readonly titulo = computed(() => {
    switch (this.situacao()) {
      case 'pro':
        return 'O sistema web faz parte do Black Belt';
      case 'suspenso':
        return 'Assinatura suspensa';
      default:
        return 'Seu período de teste terminou';
    }
  });

  readonly explicacao = computed(() => {
    switch (this.situacao()) {
      case 'pro':
        return 'Sua academia assina o Sensei PRO, que vale para o aplicativo. Para usar pelo computador, mude para o Sensei Black Belt.';
      case 'suspenso':
        return 'A cobrança não foi aprovada e o acesso pago está pausado. Atualize a forma de pagamento na loja onde a assinatura foi feita.';
      default:
        return 'Para continuar usando o sistema web, assine o Sensei Black Belt. O plano gratuito continua disponível no aplicativo.';
    }
  });

  readonly passos = computed(() => {
    if (this.situacao() === 'suspenso') {
      return [
        'Abra a App Store ou o Google Play no celular onde a assinatura foi feita.',
        'Em assinaturas, atualize a forma de pagamento.',
        'Depois da cobrança aprovada, volte aqui e verifique novamente.',
      ];
    }
    return [
      this.situacao() === 'pro'
        ? 'Abra o app Sensei Manager no celular onde a assinatura foi feita.'
        : 'Instale o app Sensei Manager e entre com este mesmo login.',
      'Vá em Configurações e toque no seu plano.',
      'Escolha Black Belt (app + web) e conclua a assinatura.',
      'Volte aqui e verifique novamente.',
    ];
  });

  ngOnInit(): void {
    void this.conferir(false);
  }

  async conferir(avisar = true): Promise<void> {
    this.verificando.set(true);
    this.aviso.set('');
    const acesso = await this.acessoService.verificar(true);
    this.verificando.set(false);

    if (!acesso || acesso.liberado) {
      await this.router.navigate(['/app/dashboard']);
      return;
    }
    if (avisar) {
      this.aviso.set('Ainda não encontramos o Black Belt nesta academia. A confirmação da loja pode levar alguns minutos.');
    }
  }

  sair(): void {
    void this.authService.logout();
  }
}
