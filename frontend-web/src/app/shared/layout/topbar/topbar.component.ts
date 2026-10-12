import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { FirebaseAuthService } from '../../../core/services/firebase-auth.service';
import { ThemeService } from '../../../core/services/theme.service';
import { NotificacaoService } from '../../../core/services/notificacao.service';
import { LayoutService } from '../../../core/services/layout.service';
import { NotificacaoDto } from '../../../core/models/notificacao.model';

@Component({
  selector: 'app-topbar',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './topbar.component.html',
  styleUrls: ['./topbar.component.css'],
})
export class TopbarComponent implements OnInit {
  readonly authService = inject(FirebaseAuthService);
  readonly router = inject(Router);
  readonly themeService = inject(ThemeService);
  readonly layoutService = inject(LayoutService);
  private readonly notifService = inject(NotificacaoService);

  readonly dropdownAberto = signal(false);
  readonly notifAberto = signal(false);
  readonly planoGratuito = signal(true);
  readonly upgradeAberto = signal(false);
  readonly notificacoes = signal<NotificacaoDto[]>([]);
  readonly carregandoNotif = signal(false);

  readonly naoLidas = computed(() => this.notificacoes().filter(n => !n.lida).length);
  readonly notifVisiveis = computed(() => this.notificacoes());

  private readonly uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

  ngOnInit(): void {
    this.notifService.listar().subscribe({
      next: r => this.notificacoes.set(r.dados ?? []),
    });
  }

  get breadcrumb(): string {
    const url = this.router.url.split('?')[0];
    const segmentos = url.split('/').filter((s) => Boolean(s) && s !== 'app' && !this.uuidRegex.test(s));

    if (segmentos.length === 0) return 'Dashboard';

    const mapa: Record<string, string> = {
      dashboard: 'Dashboard',
      alunos: 'Alunos',
      funcionarios: 'Professores & Funcionários',
      modalidades: 'Modalidades',
      turmas: 'Turmas',
      horarios: 'Horários',
      presencas: 'Presenças',
      graduacao: 'Graduação',
      ranking: 'Ranking',
      perfil: 'Perfil Gamificado',
      configuracoes: 'Configurações',
      'forgot-password': 'Recuperar senha',
      novo: 'Novo',
      editar: 'Editar',
      historico: 'Histórico',
      faixas: 'Faixas',
      registrar: 'Registrar',
      detalhe: 'Detalhe',
      catraca: 'Catraca',
    };

    return segmentos.map((s) => mapa[s] ?? s).join(' / ');
  }

  abrirUpgrade(): void {
    this.upgradeAberto.set(true);
    if (this.dropdownAberto()) this.dropdownAberto.set(false);
    if (this.notifAberto()) this.notifAberto.set(false);
  }

  alternarDropdown(): void {
    this.dropdownAberto.update((v) => !v);
    if (this.notifAberto()) this.notifAberto.set(false);
  }

  fecharDropdown(): void {
    this.dropdownAberto.set(false);
  }

  abrirNotificacoes(): void {
    const abrindo = !this.notifAberto();
    this.notifAberto.set(abrindo);
    if (this.dropdownAberto()) this.dropdownAberto.set(false);
    if (abrindo) this.carregarNotificacoes();
  }

  fecharNotificacoes(): void {
    this.notifAberto.set(false);
  }

  carregarNotificacoes(): void {
    this.carregandoNotif.set(true);
    this.notifService.listar().subscribe({
      next: r => { this.notificacoes.set(r.dados ?? []); this.carregandoNotif.set(false); },
      error: () => this.carregandoNotif.set(false),
    });
  }

  marcarLida(id: string): void {
    this.notifService.marcarLida(id).subscribe({
      next: () => this.notificacoes.update(list =>
        list.map(n => n.id === id ? { ...n, lida: true } : n)
      ),
    });
  }

  marcarTodasLidas(): void {
    this.notifService.marcarTodasLidas().subscribe({
      next: () => this.notificacoes.update(list => list.map(n => ({ ...n, lida: true }))),
    });
  }

  excluir(id: string): void {
    this.notifService.excluir(id).subscribe({
      next: () => this.notificacoes.update(list => list.filter(n => n.id !== id)),
    });
  }

  /** O mobile não calcula isso (não exibe hora na lista de notificações) — exibição extra só no CRM, não altera nenhum dado. */
  tempoRelativo(criadoEm: string): string {
    if (!criadoEm) return '';
    const diffMs = Date.now() - new Date(criadoEm).getTime();
    const min = Math.floor(diffMs / 60000);
    if (min < 1) return 'agora';
    if (min < 60) return `há ${min} min`;
    const horas = Math.floor(min / 60);
    if (horas < 24) return `há ${horas}h`;
    const dias = Math.floor(horas / 24);
    return `há ${dias}d`;
  }

  iconeTipo(tipo: string): string {
    if (tipo === 'aniversario') return '🎂';
    if (tipo === 'alerta') return '⚠️';
    if (tipo === 'solicitacao_senha') return '🔑';
    if (tipo === 'cobranca_gerada') return '🧾';
    if (tipo === 'graduacao') return '🏆';
    if (tipo === 'atestado_pendente') return '📋';
    return 'ℹ️';
  }

  sair(): void {
    this.fecharDropdown();
    this.authService.logout();
  }
}
