import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink, ActivatedRoute, Router } from '@angular/router';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';
import { AlunoService } from '../../../../core/services/aluno.service';
import { PresencaService } from '../../../../core/services/presenca.service';
import { RankingService } from '../../../../core/services/ranking.service';
import { FinanceiroService } from '../../../../core/services/financeiro.service';
import { GraduacaoService } from '../../../../core/services/graduacao.service';
import { ToastService } from '../../../../core/services/toast.service';
import { ModalidadeService, ModalidadeDto } from '../../../../core/services/modalidade.service';
import { UsuarioService } from '../../../../core/services/usuario.service';
import { ContratoService } from '../../../../core/services/contrato.service';
import { ModeloContratoService } from '../../../../core/services/modelo-contrato.service';
import { AlunoDetalheDto } from '../../../../core/models/aluno.model';
import { PresencaDto } from '../../../../core/models/presenca.model';
import { PerfilGamificadoDto } from '../../../../core/models/ranking.model';
import { PagamentoDto, CreatePagamentoRequest } from '../../../../core/models/financeiro.model';
import { FaixaDto, GraduacaoDto, RegistrarGraduacaoRequest } from '../../../../core/models/graduacao.model';
import { UsuarioResumoDto } from '../../../../core/models/usuario.model';
import { ContratoDto, ContratoDetalheDto, ModeloContratoDto } from '../../../../core/models/contrato.model';
import { NivelBadgeComponent } from '../../../../shared/components/nivel-badge/nivel-badge.component';
import { AtestadoService } from '../../../../core/services/atestado.service';
import { AtestadoMedicoComArquivoDto, AvaliarAtestadoRequest } from '../../../../core/models/atestado.model';
import { GruposFamiliaresService, GrupoFamiliarDto, MembroDto } from '../../../../core/services/grupos-familiares.service';
import { AlunoListaDto } from '../../../../core/models/aluno.model';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../../../environments/environment';

type Aba = 'info' | 'presencas' | 'financeiro' | 'ranking' | 'contratos' | 'atestado' | 'parq';

@Component({
  selector: 'app-aluno-detalhe',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink, NivelBadgeComponent],
  templateUrl: './aluno-detalhe.component.html',
})
export class AlunoDetalheComponent implements OnInit {
  private readonly alunoService = inject(AlunoService);
  private readonly presencaService = inject(PresencaService);
  private readonly rankingService = inject(RankingService);
  private readonly financeiroService = inject(FinanceiroService);
  private readonly graduacaoService = inject(GraduacaoService);
  private readonly toastService = inject(ToastService);
  private readonly modalidadeService = inject(ModalidadeService);
  private readonly usuarioService = inject(UsuarioService);
  private readonly contratoService = inject(ContratoService);
  private readonly modeloContratoService = inject(ModeloContratoService);
  private readonly atestadoService = inject(AtestadoService);
  private readonly grupoFamiliarService = inject(GruposFamiliaresService);
  private readonly http = inject(HttpClient);
  private readonly sanitizer = inject(DomSanitizer);
  private readonly route = inject(ActivatedRoute);
  private readonly router = inject(Router);

  // Core
  readonly aluno = signal<AlunoDetalheDto | null>(null);
  readonly perfil = signal<PerfilGamificadoDto | null>(null);
  readonly presencas = signal<PresencaDto[]>([]);
  readonly pagamentos = signal<PagamentoDto[]>([]);
  readonly carregando = signal(true);
  readonly carregandoPerfil = signal(false);
  readonly carregandoPresencas = signal(false);
  readonly carregandoPagamentos = signal(false);
  readonly erro = signal('');
  readonly tabAtiva = signal<Aba>('info');
  readonly presencasDe = signal(this.primeiroDiaMes());
  readonly presencasAte = signal(new Date().toISOString().split('T')[0]);

  // Contratos
  readonly contratos = signal<ContratoDto[]>([]);
  readonly carregandoContratos = signal(false);
  readonly erroContratos = signal('');
  // Inline contract view (#2)
  readonly contratoDetalhe = signal<ContratoDetalheDto | null>(null);
  readonly contratoConteudoSafe = signal<SafeHtml>('');
  readonly carregandoContratoDetalhe = signal(false);
  readonly linkCopiado = signal(false);
  // Contract create modal (#1)
  readonly modalContratoAberto = signal(false);
  readonly criandoContrato = signal(false);
  readonly erroCriacaoContrato = signal('');
  readonly contratoModalidadeId = signal('');
  readonly contratoAvisoExistente = signal('');
  readonly modelos = signal<ModeloContratoDto[]>([]);
  readonly contratoModeloId = signal('');

  // PAR-Q
  readonly parq = signal<Record<string, unknown> | null>(null);
  readonly carregandoParQ = signal(false);
  readonly erroParQ = signal('');

  // Atestado
  readonly atestado = signal<AtestadoMedicoComArquivoDto | null>(null);
  readonly carregandoAtestado = signal(false);
  readonly erroAtestado = signal('');
  readonly motivoRejeicao = signal('');
  readonly uploadAtestadoBase64 = signal('');
  readonly uploadAtestadoMime = signal('application/pdf');
  readonly uploadAtestadoNome = signal('');
  readonly uploadAtestadoValidade = signal('');
  readonly salvandoAtestado = signal(false);

  // Graduation history
  readonly graduacoes = signal<GraduacaoDto[]>([]);
  readonly carregandoGraduacoes = signal(false);

  readonly graduacoesPorModalidade = computed(() => {
    const map = new Map<string, GraduacaoDto>();
    for (const g of this.graduacoes()) {
      if (!g.aprovado) continue;
      const existing = map.get(g.modalidadeId);
      if (!existing || g.faixaOrdem > existing.faixaOrdem) {
        map.set(g.modalidadeId, g);
      }
    }
    return Array.from(map.values());
  });

  // Grupo Familiar
  readonly grupoFamiliar = signal<GrupoFamiliarDto | null>(null);
  readonly carregandoGrupoFamiliar = signal(false);
  readonly modalCriarGrupoAberto = signal(false);
  readonly modalAssociarGrupoAberto = signal(false);
  readonly modalAdicionarMembroGrupoAberto = signal(false);
  readonly nomeGrupoModal = signal('');
  readonly erroGrupoModal = signal('');
  readonly salvandoGrupo = signal(false);
  readonly listaGrupos = signal<GrupoFamiliarDto[]>([]);
  readonly carregandoListaGrupos = signal(false);
  readonly buscaAlunoGrupo = signal('');
  readonly resultadosBuscaGrupo = signal<AlunoListaDto[]>([]);
  readonly buscandoAlunoGrupo = signal(false);
  private buscaGrupoTimer: ReturnType<typeof setTimeout> | null = null;

  // Graduation modal (#7)
  readonly modalidades = signal<ModalidadeDto[]>([]);
  readonly professores = signal<UsuarioResumoDto[]>([]);
  readonly faixasGrad = signal<FaixaDto[]>([]);
  readonly modalGraduacaoAberto = signal(false);
  readonly gradModalidadeId = signal('');
  readonly gradFaixaId = signal('');
  readonly gradProfessorId = signal('');
  readonly gradData = signal(new Date().toISOString().split('T')[0]);
  readonly gradObservacoes = signal('');
  readonly gradGerarCobranca = signal(false);
  readonly gradValorCobranca = signal('');
  readonly registrandoGrad = signal(false);
  readonly erroGrad = signal('');
  readonly graduacaoOk = signal(false);

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id')!;
    this.alunoService.getById(id).subscribe({
      next: (res) => {
        this.aluno.set(res.dados ?? null);
        this.carregando.set(false);
        if (res.dados) {
          this.carregarPerfil(id);
          this.carregarPresencas(id);
          this.carregarPagamentos(id);
          this.carregarGraduacoes(id);
          this.carregarGrupoFamiliar(id);
        }
      },
      error: () => { this.erro.set('Aluno não encontrado.'); this.carregando.set(false); },
    });
    this.modalidadeService.getAll().subscribe({ next: r => this.modalidades.set(r.dados ?? []) });
    this.usuarioService.getProfessores().subscribe({ next: r => this.professores.set(r.dados ?? []) });
    this.modeloContratoService.listar().subscribe({ next: r => this.modelos.set(r.dados ?? []) });
  }

  private carregarPerfil(id: string): void {
    this.carregandoPerfil.set(true);
    this.rankingService.getPerfilGamificado(id).subscribe({
      next: (p) => { this.perfil.set(p); this.carregandoPerfil.set(false); },
      error: () => this.carregandoPerfil.set(false),
    });
  }

  carregarPresencas(id: string): void {
    this.carregandoPresencas.set(true);
    this.presencaService.getHistorico(id, this.presencasDe(), this.presencasAte()).subscribe({
      next: (res) => { this.presencas.set(res.dados ?? []); this.carregandoPresencas.set(false); },
      error: () => this.carregandoPresencas.set(false),
    });
  }

  readonly totalPago = computed(() =>
    this.pagamentos().filter(p => p.status === 'Pago').reduce((s, p) => s + p.valor, 0));
  readonly totalPendente = computed(() =>
    this.pagamentos().filter(p => p.status === 'Pendente').reduce((s, p) => s + p.valor, 0));
  readonly totalAtrasado = computed(() =>
    this.pagamentos().filter(p => p.status === 'Atrasado').reduce((s, p) => s + p.valor, 0));

  carregarPagamentos(id: string): void {
    this.carregandoPagamentos.set(true);
    this.financeiroService.listarPorAluno(id).subscribe({
      next: (res) => { this.pagamentos.set(res.dados ?? []); this.carregandoPagamentos.set(false); },
      error: () => this.carregandoPagamentos.set(false),
    });
  }

  marcarPagamentoPago(p: PagamentoDto): void {
    const hoje = new Date().toISOString().split('T')[0];
    this.financeiroService.atualizar(p.id, { status: 1, dataPagamento: hoje }).subscribe({
      next: () => this.carregarPagamentos(this.aluno()!.id),
    });
  }

  wppLink(telefone: string): string {
    return `https://wa.me/55${telefone.replace(/\D/g, '')}`;
  }

  // ─── Contratos ───────────────────────────────────────────────

  carregarContratos(alunoId: string): void {
    this.carregandoContratos.set(true);
    this.contratoDetalhe.set(null);
    this.contratoService.listar(alunoId).subscribe({
      next: res => { this.contratos.set(res.dados ?? []); this.carregandoContratos.set(false); },
      error: () => { this.erroContratos.set('Erro ao carregar contratos.'); this.carregandoContratos.set(false); },
    });
  }

  abrirModalNovoContrato(): void {
    this.contratoModalidadeId.set('');
    this.contratoModeloId.set('');
    this.erroCriacaoContrato.set('');
    this.contratoAvisoExistente.set('');
    this.modalContratoAberto.set(true);
  }

  onContratoModalidadeChange(): void {
    const modalidadeId = this.contratoModalidadeId();
    if (!modalidadeId) { this.contratoAvisoExistente.set(''); return; }
    const existente = this.contratos().find(
      c => c.modalidadeId === modalidadeId && c.status !== 3
    );
    if (existente) {
      const status = existente.status === 2 ? 'assinado' : 'pendente';
      this.contratoAvisoExistente.set(`Já existe um contrato ${status} para esta modalidade. Ao confirmar, ele será descartado e substituído.`);
    } else {
      this.contratoAvisoExistente.set('');
    }
  }

  criarContrato(): void {
    const id = this.aluno()?.id;
    if (!id) return;
    this.criandoContrato.set(true);
    this.erroCriacaoContrato.set('');
    this.contratoService.criar({
      alunoId: id,
      modalidadeId: this.contratoModalidadeId() || undefined,
      modeloContratoId: this.contratoModeloId() || undefined,
    }).subscribe({
      next: res => {
        this.criandoContrato.set(false);
        if (res.sucesso) {
          this.modalContratoAberto.set(false);
          this.carregarContratos(id);
        } else {
          this.erroCriacaoContrato.set(res.mensagem ?? 'Erro ao criar contrato.');
        }
      },
      error: err => {
        this.criandoContrato.set(false);
        this.erroCriacaoContrato.set(err.error?.mensagem ?? 'Erro ao criar contrato.');
      },
    });
  }

  verContratoInline(contratoId: string): void {
    this.carregandoContratoDetalhe.set(true);
    this.contratoDetalhe.set(null);
    this.contratoService.obter(contratoId).subscribe({
      next: res => {
        if (res.dados) {
          this.contratoDetalhe.set(res.dados);
          this.contratoConteudoSafe.set(this.sanitizer.bypassSecurityTrustHtml(res.dados.conteudoHtml));
        }
        this.carregandoContratoDetalhe.set(false);
      },
      error: () => this.carregandoContratoDetalhe.set(false),
    });
  }

  fecharContratoInline(): void {
    this.contratoDetalhe.set(null);
  }

  linkPublicoContrato(): string {
    const token = this.contratoDetalhe()?.tokenPublico;
    return token ? `${window.location.origin}/assinar/${token}` : '';
  }

  copiarLinkContrato(): void {
    navigator.clipboard.writeText(this.linkPublicoContrato()).then(() => {
      this.linkCopiado.set(true);
      setTimeout(() => this.linkCopiado.set(false), 2500);
    });
  }

  enviarWppContrato(): void {
    const detalhe = this.contratoDetalhe();
    if (!detalhe || !this.aluno()?.telefone) return;
    const telefone = this.aluno()!.telefone!.replace(/\D/g, '');
    const link = this.linkPublicoContrato();
    const texto = encodeURIComponent(`Olá ${detalhe.nomeAluno}, segue o link para assinar seu contrato:\n${link}`);
    window.open(`https://wa.me/55${telefone}?text=${texto}`, '_blank');
  }

  imprimirContrato(): void {
    const html = this.contratoDetalhe()?.conteudoHtml ?? '';
    const janela = window.open('', '_blank', 'width=800,height=900');
    if (!janela) return;
    janela.document.write(`<!DOCTYPE html><html lang="pt-BR"><head><meta charset="UTF-8"><title>Contrato</title><style>body{font-family:Arial,sans-serif;padding:40px 60px;font-size:14px;line-height:1.7;color:#111;}h2{font-size:20px;margin-bottom:12px;}h3{font-size:15px;margin:20px 0 8px;}p{margin-bottom:6px;}hr{border:none;border-top:1px solid #ccc;margin:16px 0;}</style></head><body>${html}</body></html>`);
    janela.document.close();
    janela.onload = () => { janela.print(); };
  }

  badgeClassContrato(status: number): string {
    if (status === 2) return 'badge-ct-assinado';
    if (status === 3) return 'badge-ct-cancelado';
    return 'badge-ct-pendente';
  }

  carregarGraduacoes(id: string): void {
    this.carregandoGraduacoes.set(true);
    this.graduacaoService.getHistoricoAluno(id).subscribe({
      next: r => { this.graduacoes.set(r.dados ?? []); this.carregandoGraduacoes.set(false); },
      error: () => this.carregandoGraduacoes.set(false),
    });
  }

  // ─── Graduation ──────────────────────────────────────────────

  abrirModalGraduacao(modalidadePreSelecionada?: string): void {
    this.gradModalidadeId.set(modalidadePreSelecionada ?? '');
    this.gradFaixaId.set('');
    this.gradProfessorId.set('');
    this.gradData.set(new Date().toISOString().split('T')[0]);
    this.gradObservacoes.set('');
    this.gradGerarCobranca.set(false);
    this.gradValorCobranca.set('');
    this.erroGrad.set('');
    this.graduacaoOk.set(false);
    this.faixasGrad.set([]);
    this.modalGraduacaoAberto.set(true);
    if (modalidadePreSelecionada) this.onGradModalidadeChange();
  }

  onGradModalidadeChange(): void {
    const mid = this.gradModalidadeId();
    this.gradFaixaId.set('');
    this.faixasGrad.set([]);
    if (!mid) return;
    this.graduacaoService.getFaixasByModalidade(mid).subscribe({
      next: r => this.faixasGrad.set(r.dados ?? []),
    });
  }

  registrarGraduacao(): void {
    const alunoId = this.aluno()?.id;
    if (!alunoId) return;
    if (!this.gradFaixaId()) { this.erroGrad.set('Selecione a faixa/graduação.'); return; }
    if (!this.gradProfessorId()) { this.erroGrad.set('Selecione o professor responsável.'); return; }
    if (!this.gradData()) { this.erroGrad.set('Informe a data do exame.'); return; }

    this.registrandoGrad.set(true);
    this.erroGrad.set('');
    const req: RegistrarGraduacaoRequest = {
      alunoId,
      faixaId: this.gradFaixaId(),
      professorId: this.gradProfessorId(),
      dataExame: this.gradData(),
      aprovado: true,
      grau: 0,
      observacoes: this.gradObservacoes() || undefined,
    };

    this.graduacaoService.registrar(req).subscribe({
      next: res => {
        this.registrandoGrad.set(false);
        if (res.sucesso) {
          this.modalGraduacaoAberto.set(false);
          if (this.gradGerarCobranca() && this.gradValorCobranca()) {
            const valor = parseFloat(this.gradValorCobranca().replace(',', '.'));
            if (valor > 0) {
              const faixaNome = this.faixasGrad().find(f => f.id === this.gradFaixaId())?.nome ?? 'Graduação';
              const hoje = new Date();
              const dataVencimento = `${hoje.getFullYear()}-${String(hoje.getMonth() + 1).padStart(2, '0')}-${String(hoje.getDate()).padStart(2, '0')}`;
              const pag: CreatePagamentoRequest = {
                alunoId,
                tipo: 5,
                status: 2,
                valor,
                descricao: `Graduação - ${faixaNome}`,
                dataVencimento,
              };
              this.financeiroService.criar(pag).subscribe();
            }
          }
          this.toastService.success('Graduação registrada com sucesso!');
          this.recarregarAluno();
          this.carregarPagamentos(alunoId);
          this.carregarGraduacoes(alunoId);
        } else {
          this.erroGrad.set(res.mensagem ?? 'Erro ao registrar.');
        }
      },
      error: err => { this.registrandoGrad.set(false); this.erroGrad.set(err.error?.mensagem ?? 'Erro ao registrar.'); },
    });
  }

  // ─── PAR-Q ───────────────────────────────────────────────────

  carregarParQ(alunoId: string): void {
    this.carregandoParQ.set(true);
    this.erroParQ.set('');
    this.http.get<{ sucesso: boolean; dados: Record<string, unknown> | null }>(`${environment.apiUrl}/api/parq/aluno/${alunoId}`).subscribe({
      next: res => { this.parq.set(res.dados ?? null); this.carregandoParQ.set(false); },
      error: () => { this.erroParQ.set('Erro ao carregar PAR-Q.'); this.carregandoParQ.set(false); },
    });
  }

  parqPergunta(numero: number): string {
    const p: Record<number, string> = {
      1: 'Problema de coração/pressão com restrição médica',
      2: 'Dores no peito ao praticar atividade física',
      3: 'Dores no peito no último mês',
      4: 'Desequilíbrio/tontura/perda de consciência',
      5: 'Problema ósseo ou articular agravado por atividade física',
      6: 'Medicação de uso contínuo',
      7: 'Tratamento médico para pressão/problemas cardíacos',
      8: 'Tratamento médico contínuo afetado por atividade física',
      9: 'Cirurgia que comprometa atividade física',
      10: 'Outra razão que pode comprometer a saúde',
    };
    return p[numero] ?? '';
  }

  parqResposta(numero: number): boolean {
    return !!(this.parq() as Record<string, unknown>)?.[`r${numero}`];
  }

  // ─── Atestado ────────────────────────────────────────────────

  carregarAtestado(alunoId: string): void {
    this.carregandoAtestado.set(true);
    this.erroAtestado.set('');
    this.atestadoService.obterDoAluno(alunoId).subscribe({
      next: res => { this.atestado.set(res.dados ?? null); this.carregandoAtestado.set(false); },
      error: () => { this.erroAtestado.set('Erro ao carregar atestado.'); this.carregandoAtestado.set(false); },
    });
  }

  avaliarAtestado(aprovado: boolean): void {
    const a = this.atestado();
    if (!a) return;
    const req: AvaliarAtestadoRequest = { aprovado, motivoRejeicao: aprovado ? undefined : (this.motivoRejeicao() || undefined) };
    this.salvandoAtestado.set(true);
    this.atestadoService.avaliar(a.id, req).subscribe({
      next: () => { this.salvandoAtestado.set(false); this.carregarAtestado(a.alunoId); this.toastService.success(aprovado ? 'Atestado aprovado!' : 'Atestado rejeitado.'); },
      error: () => { this.salvandoAtestado.set(false); this.toastService.error('Erro ao avaliar atestado.'); },
    });
  }

  onAtestadoFileChange(event: Event): void {
    const input = event.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;
    if (file.size > 5 * 1024 * 1024) { this.toastService.error('Arquivo muito grande (máx 5 MB).'); return; }
    this.uploadAtestadoMime.set(file.type || 'application/pdf');
    this.uploadAtestadoNome.set(file.name);
    const reader = new FileReader();
    reader.onload = () => {
      const result = (reader.result as string).split(',')[1] ?? '';
      this.uploadAtestadoBase64.set(result);
    };
    reader.readAsDataURL(file);
  }

  uploadAtestadoAcademia(): void {
    const alunoId = this.aluno()?.id;
    if (!alunoId || !this.uploadAtestadoBase64()) return;
    this.salvandoAtestado.set(true);
    this.atestadoService.uploadPorAcademia({
      alunoId,
      arquivoBase64: this.uploadAtestadoBase64(),
      arquivoMimeType: this.uploadAtestadoMime(),
      arquivoNome: this.uploadAtestadoNome() || undefined,
    }).subscribe({
      next: () => {
        this.salvandoAtestado.set(false);
        this.uploadAtestadoBase64.set('');
        this.uploadAtestadoNome.set('');
        this.carregarAtestado(alunoId);
        this.toastService.success('Atestado enviado!');
      },
      error: err => { this.salvandoAtestado.set(false); this.toastService.error(err.error?.mensagem ?? 'Erro ao enviar atestado.'); },
    });
  }

  enviarLembreteAtestado(): void {
    const alunoId = this.aluno()?.id;
    if (!alunoId) return;
    this.atestadoService.enviarLembrete(alunoId).subscribe({
      next: () => this.toastService.success('Lembrete enviado!'),
      error: () => this.toastService.error('Erro ao enviar lembrete.'),
    });
  }

  atestadoStatusLabel(status: number): string {
    const m: Record<number, string> = { 0: 'Pendente', 1: 'Aprovado', 2: 'Rejeitado', 3: 'Expirado' };
    return m[status] ?? '—';
  }

  atestadoStatusClass(status: number): string {
    const m: Record<number, string> = { 0: 'badge-pag-pendente', 1: 'badge-pag-pago', 2: 'badge-pag-atrasado', 3: 'badge-pag-cancelado' };
    return m[status] ?? '';
  }

  abrirArquivoAtestado(): void {
    const a = this.atestado();
    if (!a?.arquivoBase64) return;
    const blob = this.base64ToBlob(a.arquivoBase64, a.arquivoMimeType);
    const url = URL.createObjectURL(blob);
    window.open(url, '_blank');
  }

  private base64ToBlob(b64: string, mime: string): Blob {
    const byteChars = atob(b64);
    const byteNums = Array.from(byteChars, c => c.charCodeAt(0));
    return new Blob([new Uint8Array(byteNums)], { type: mime });
  }

  private recarregarAluno(): void {
    const id = this.route.snapshot.paramMap.get('id')!;
    this.alunoService.getById(id).subscribe({ next: r => this.aluno.set(r.dados ?? null) });
  }

  // ─── Grupo Familiar ──────────────────────────────────────────

  carregarGrupoFamiliar(alunoId: string): void {
    this.carregandoGrupoFamiliar.set(true);
    this.grupoFamiliarService.obterPorAluno(alunoId).subscribe({
      next: res => { this.grupoFamiliar.set(res.dados ?? null); this.carregandoGrupoFamiliar.set(false); },
      error: () => this.carregandoGrupoFamiliar.set(false),
    });
  }

  abrirCriarGrupo(): void {
    this.nomeGrupoModal.set('');
    this.erroGrupoModal.set('');
    this.modalCriarGrupoAberto.set(true);
  }

  confirmarCriarGrupo(): void {
    if (!this.nomeGrupoModal().trim()) { this.erroGrupoModal.set('Nome é obrigatório.'); return; }
    const alunoId = this.aluno()?.id;
    if (!alunoId) return;
    this.salvandoGrupo.set(true);
    this.erroGrupoModal.set('');
    this.grupoFamiliarService.criar(this.nomeGrupoModal().trim()).subscribe({
      next: res => {
        if (res.dados) {
          this.grupoFamiliarService.adicionarMembro(res.dados.id, alunoId).subscribe({
            next: () => { this.fecharModalGrupo(); this.carregarGrupoFamiliar(alunoId); this.salvandoGrupo.set(false); },
            error: () => { this.erroGrupoModal.set('Grupo criado, mas erro ao vincular aluno.'); this.salvandoGrupo.set(false); },
          });
        }
      },
      error: () => { this.erroGrupoModal.set('Erro ao criar grupo.'); this.salvandoGrupo.set(false); },
    });
  }

  abrirAssociarGrupo(): void {
    this.erroGrupoModal.set('');
    this.modalAssociarGrupoAberto.set(true);
    this.carregandoListaGrupos.set(true);
    this.grupoFamiliarService.listar().subscribe({
      next: res => { this.listaGrupos.set(res.dados ?? []); this.carregandoListaGrupos.set(false); },
      error: () => this.carregandoListaGrupos.set(false),
    });
  }

  confirmarAssociarGrupo(grupoId: string): void {
    const alunoId = this.aluno()?.id;
    if (!alunoId) return;
    this.salvandoGrupo.set(true);
    this.erroGrupoModal.set('');
    this.grupoFamiliarService.adicionarMembro(grupoId, alunoId).subscribe({
      next: () => { this.fecharModalGrupo(); this.carregarGrupoFamiliar(alunoId); this.salvandoGrupo.set(false); },
      error: () => { this.erroGrupoModal.set('Erro ao vincular ao grupo.'); this.salvandoGrupo.set(false); },
    });
  }

  abrirAdicionarMembroGrupo(): void {
    this.buscaAlunoGrupo.set('');
    this.resultadosBuscaGrupo.set([]);
    this.erroGrupoModal.set('');
    this.modalAdicionarMembroGrupoAberto.set(true);
  }

  onBuscaAlunoGrupo(valor: string): void {
    this.buscaAlunoGrupo.set(valor);
    if (this.buscaGrupoTimer) clearTimeout(this.buscaGrupoTimer);
    if (!valor.trim()) { this.resultadosBuscaGrupo.set([]); return; }
    this.buscaGrupoTimer = setTimeout(() => {
      this.buscandoAlunoGrupo.set(true);
      this.alunoService.buscarPorNome(valor).subscribe({
        next: res => { this.resultadosBuscaGrupo.set(res.dados?.itens ?? []); this.buscandoAlunoGrupo.set(false); },
        error: () => this.buscandoAlunoGrupo.set(false),
      });
    }, 350);
  }

  confirmarAdicionarMembroGrupo(aluno: AlunoListaDto): void {
    const grupo = this.grupoFamiliar();
    if (!grupo) return;
    this.salvandoGrupo.set(true);
    this.grupoFamiliarService.adicionarMembro(grupo.id, aluno.id).subscribe({
      next: () => {
        this.fecharModalGrupo();
        this.carregarGrupoFamiliar(this.aluno()!.id);
        this.salvandoGrupo.set(false);
      },
      error: () => { this.erroGrupoModal.set('Erro ao adicionar membro.'); this.salvandoGrupo.set(false); },
    });
  }

  sairDoGrupo(): void {
    const grupo = this.grupoFamiliar();
    const alunoId = this.aluno()?.id;
    if (!grupo || !alunoId) return;
    this.grupoFamiliarService.removerMembro(grupo.id, alunoId).subscribe({
      next: () => { this.grupoFamiliar.set(null); },
    });
  }

  removerMembroGrupo(membroId: string): void {
    const grupo = this.grupoFamiliar();
    if (!grupo) return;
    this.grupoFamiliarService.removerMembro(grupo.id, membroId).subscribe({
      next: () => this.carregarGrupoFamiliar(this.aluno()!.id),
    });
  }

  fecharModalGrupo(): void {
    this.modalCriarGrupoAberto.set(false);
    this.modalAssociarGrupoAberto.set(false);
    this.modalAdicionarMembroGrupoAberto.set(false);
  }

  iniciais(nome: string): string {
    return nome.split(' ').slice(0, 2).map(w => w[0] ?? '').join('').toUpperCase();
  }

  // ─── Utils ───────────────────────────────────────────────────

  voltar(): void { this.router.navigate(['/app/alunos']); }

  avatarInicial(nome: string): string { return (nome ?? 'A').charAt(0).toUpperCase(); }

  faixaCor(cor?: string): string { return cor ?? '#94a3b8'; }

  formatarData(d?: string): string {
    if (!d) return '—';
    const [y, m, day] = d.split('-');
    return `${day}/${m}/${y}`;
  }

  formatarDataHora(d?: string): string {
    if (!d) return '—';
    return new Date(d).toLocaleString('pt-BR');
  }

  formatarMoeda(valor: number): string {
    return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }

  badgeStatusPag(status: string): string {
    const map: Record<string, string> = {
      Pago: 'badge-pag-pago', Pendente: 'badge-pag-pendente',
      Atrasado: 'badge-pag-atrasado', Cancelado: 'badge-pag-cancelado',
    };
    return map[status] ?? '';
  }

  private primeiroDiaMes(): string {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-01`;
  }
}
