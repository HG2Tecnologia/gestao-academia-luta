import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../../core/services/auth.service';
import { ThemeService } from '../../../core/services/theme.service';
import { NotificacaoService } from '../../../core/services/notificacao.service';
import { SignalrService } from '../../../core/services/signalr.service';
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
  readonly authService = inject(AuthService);
  readonly router = inject(Router);
  readonly themeService = inject(ThemeService);
  readonly layoutService = inject(LayoutService);
  private readonly notifService = inject(NotificacaoService);
  private readonly signalrService = inject(SignalrService);

  readonly dropdownAberto = signal(false);
  readonly notifAberto = signal(false);
  readonly notificacoes = signal<NotificacaoDto[]>([]);
  readonly carregandoNotif = signal(false);

  readonly naoLidas = computed(() => this.notificacoes().filter(n => !n.lida && n.titulo !== '_dedup').length);
  readonly notifVisiveis = computed(() => this.notificacoes().filter(n => n.titulo !== '_dedup'));

  private readonly uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

  ngOnInit(): void {
    // Load initial notification count silently
    this.notifService.listar().subscribe({
      next: r => this.notificacoes.set(r.dados ?? []),
    });

    // Connect SignalR and listen for new notifications
    const token = this.authService.getAccessToken();
    const user = this.authService.currentUser();
    if (token && user?.academia_id) {
      this.signalrService.startConnection(user.academia_id, token)
        .then(() => {
          this.signalrService.onNovaNotificacao(() => {
            // Reload full list to get the new notification
            this.notifService.listar().subscribe({
              next: r => this.notificacoes.set(r.dados ?? []),
            });
          });
        })
        .catch(() => {});
    }
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

  iconeTipo(tipo: string): string {
    if (tipo === 'aniversario') return '🎂';
    if (tipo === 'alerta') return '⚠️';
    return 'ℹ️';
  }

  sair(): void {
    this.fecharDropdown();
    this.authService.logout();
  }
}
