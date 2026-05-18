import { Component, inject, signal, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { IsActiveMatchOptions, Router, RouterLink, RouterLinkActive, NavigationEnd } from '@angular/router';
import { filter } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { Subject } from 'rxjs';
import { AuthService } from '../../../core/services/auth.service';
import { AcademiaService } from '../../../core/services/academia.service';
import { LayoutService } from '../../../core/services/layout.service';

interface NavItem {
  label: string;
  rota: string;
  icone: string;
  linkOptions: IsActiveMatchOptions;
  roles?: string[];
  permissao?: string;
}

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule, RouterLink, RouterLinkActive],
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.css'],
})
export class SidebarComponent implements OnInit, OnDestroy {
  readonly authService = inject(AuthService);
  readonly layoutService = inject(LayoutService);
  private readonly academiaService = inject(AcademiaService);
  private readonly router = inject(Router);
  private readonly destroy$ = new Subject<void>();

  readonly academiaName = signal('Academia Fight');

  readonly exactMatch: IsActiveMatchOptions = {
    paths: 'exact', queryParams: 'ignored', fragment: 'ignored', matrixParams: 'ignored',
  };
  readonly subsetMatch: IsActiveMatchOptions = {
    paths: 'subset', queryParams: 'ignored', fragment: 'ignored', matrixParams: 'ignored',
  };

  readonly navItems: NavItem[] = [
    { label: 'Dashboard',    rota: '/app/dashboard',    icone: 'home',           linkOptions: this.exactMatch },
    { label: 'Alunos',       rota: '/app/alunos',       icone: 'user-group',     linkOptions: this.subsetMatch, permissao: 'Alunos' },
    { label: 'Turmas',       rota: '/app/turmas',       icone: 'users-group',    linkOptions: this.subsetMatch, permissao: 'Turmas' },
    { label: 'Horários',     rota: '/app/horarios',     icone: 'clock',          linkOptions: this.subsetMatch, permissao: 'Horários' },
    { label: 'Presenças',    rota: '/app/presencas',    icone: 'check-circle',   linkOptions: this.subsetMatch, permissao: 'Presenças' },
    { label: 'Graduação',    rota: '/app/graduacao',    icone: 'academic-cap',   linkOptions: this.subsetMatch, permissao: 'Graduação' },
    { label: 'Ranking',      rota: '/app/ranking',      icone: 'trophy',         linkOptions: this.subsetMatch, permissao: 'Ranking' },
    { label: 'Planos',       rota: '/app/planos',       icone: 'planos',         linkOptions: this.subsetMatch, permissao: 'Planos' },
    { label: 'Financeiro',   rota: '/app/financeiro',   icone: 'currency',       linkOptions: this.subsetMatch, permissao: 'Financeiro' },
    { label: 'Contratos',    rota: '/app/contratos',    icone: 'document-text',  linkOptions: this.subsetMatch, permissao: 'Contratos' },
    { label: 'Relatórios',   rota: '/app/relatorios',   icone: 'chart-bar',      linkOptions: this.subsetMatch, permissao: 'Relatórios' },
  ];

  readonly navItemsConfig: NavItem[] = [
    { label: 'Catraca',      rota: '/app/catraca',      icone: 'lock-open',      linkOptions: this.subsetMatch, permissao: 'Catraca' },
    { label: 'Modalidades',  rota: '/app/modalidades',  icone: 'shield-check',   linkOptions: this.subsetMatch, roles: ['Admin'] },
    { label: 'Funcionários', rota: '/app/funcionarios', icone: 'identification', linkOptions: this.subsetMatch, roles: ['Admin'] },
    { label: 'Configurações',rota: '/app/configuracoes',icone: 'cog',            linkOptions: this.subsetMatch, permissao: 'Configurações' },
  ];

  ngOnInit(): void {
    this.academiaService.getCurrent().subscribe({
      next: res => { if (res.dados?.nome) this.academiaName.set(res.dados.nome); },
    });

    // Close sidebar on mobile when navigating
    this.router.events.pipe(
      filter(e => e instanceof NavigationEnd),
      takeUntil(this.destroy$),
    ).subscribe(() => this.layoutService.fecharSidebar());
  }

  ngOnDestroy(): void { this.destroy$.next(); this.destroy$.complete(); }

  private itemVisivel(item: NavItem): boolean {
    const user = this.authService.currentUser();
    const perfil = user?.perfil ?? '';
    if (item.roles && !item.roles.includes(perfil)) return false;
    if (perfil === 'Admin') return true;
    if (!item.permissao) return true;
    return user?.permissoes?.[item.permissao] === true;
  }

  get navItemsVisiveis(): NavItem[] {
    return this.navItems.filter(item => this.itemVisivel(item));
  }

  get navItemsConfigVisiveis(): NavItem[] {
    return this.navItemsConfig.filter(item => this.itemVisivel(item));
  }

  brandMark(): string {
    return (this.academiaName() || 'A').charAt(0).toUpperCase();
  }

  sair(): void {
    this.authService.logout();
  }
}
