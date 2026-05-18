import { Component, inject, signal, computed, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { FinanceiroService } from '../../../../core/services/financeiro.service';
import { AlunoService } from '../../../../core/services/aluno.service';
import {
  PagamentoDto,
  ResumoFinanceiroDto,
  AlunoInadimplenteDto,
  CreatePagamentoRequest,
  TipoPagamento,
  StatusPagamento,
} from '../../../../core/models/financeiro.model';
import { AlunoListaDto } from '../../../../core/models/aluno.model';

type Aba = 'pagamentos' | 'inadimplentes';

const MESES = ['Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro'];

@Component({
  selector: 'app-financeiro-overview',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './financeiro-overview.component.html',
  styleUrls: ['./financeiro-overview.component.css'],
})
export class FinanceiroOverviewComponent implements OnInit {
  private readonly financeiroService = inject(FinanceiroService);
  private readonly alunoService = inject(AlunoService);

  // ── Navegação de mês ──────────────────────────────────────────
  private readonly hoje = new Date();
  readonly mesAtual = signal(this.hoje.getMonth() + 1);
  readonly anoAtual = signal(this.hoje.getFullYear());
  readonly nomeMes = computed(() => `${MESES[this.mesAtual() - 1]} ${this.anoAtual()}`);
  readonly ehMesAtual = computed(() => this.mesAtual() === this.hoje.getMonth() + 1 && this.anoAtual() === this.hoje.getFullYear());

  // ── Estado geral ──────────────────────────────────────────────
  readonly carregando = signal(true);
  readonly resumo = signal<ResumoFinanceiroDto | null>(null);
  readonly pagamentos = signal<PagamentoDto[]>([]);
  readonly alunos = signal<AlunoListaDto[]>([]);

  readonly abaAtiva = signal<Aba>('pagamentos');
  readonly filtroStatus = signal('');

  // ── Template da mensagem WhatsApp ─────────────────────────────
  readonly msgTemplate = signal('Olá {nome}! Temos um pagamento de {valor} {vencimento} em aberto. Poderia regularizar? Qualquer dúvida estamos à disposição! 😊');
  readonly modalMsgTemplate = signal(false);
  readonly msgTemplateEditando = signal('');

  // ── Dropdown de ações (3 pontinhos) ───────────────────────────
  readonly dropdownAcaoId = signal<string | null>(null);
  readonly dropdownPos = signal<{ top: number; right: number }>({ top: 0, right: 0 });

  // ── Modal novo pagamento ───────────────────────────────────────
  readonly modalNovoPagamento = signal(false);
  readonly salvando = signal(false);
  readonly erroSalvar = signal('');
  readonly modalExcluir = signal(false);
  readonly pagamentoParaExcluir = signal<PagamentoDto | null>(null);
  readonly excluindo = signal(false);

  readonly novoForm = signal<CreatePagamentoRequest>({
    alunoId: '', tipo: 1, status: 2, valor: 0,
    descricao: '', dataVencimento: '', dataPagamento: '', formaPagamento: '', observacoes: '',
  });

  readonly tiposPagamento = Object.entries(TipoPagamento).map(([k, v]) => ({ valor: Number(k), label: v }));
  readonly statusPagamento = Object.entries(StatusPagamento).map(([k, v]) => ({ valor: Number(k), label: v }));

  readonly dropdownAluno = signal(false);
  readonly filtroDropdownAluno = signal('');
  readonly alunoSelecionadoNome = signal('');

  readonly alunosFiltradosDropdown = computed(() => {
    const filtro = this.filtroDropdownAluno().toLowerCase().trim();
    return filtro ? this.alunos().filter(a => a.nome.toLowerCase().includes(filtro)) : this.alunos();
  });


  ngOnInit(): void {
    this.carregarTudo();
    this.alunoService.getAll({ pageSize: 500 }).subscribe({
      next: res => this.alunos.set(res.dados?.itens ?? []),
    });
  }

  // ── Navegação de mês ──────────────────────────────────────────
  irMesAnterior(): void {
    if (this.mesAtual() === 1) { this.mesAtual.set(12); this.anoAtual.update(a => a - 1); }
    else { this.mesAtual.update(m => m - 1); }
    this.carregarTudo();
  }

  irProximoMes(): void {
    if (this.mesAtual() === 12) { this.mesAtual.set(1); this.anoAtual.update(a => a + 1); }
    else { this.mesAtual.update(m => m + 1); }
    this.carregarTudo();
  }

  irMesAtual(): void {
    this.mesAtual.set(this.hoje.getMonth() + 1);
    this.anoAtual.set(this.hoje.getFullYear());
    this.carregarTudo();
  }

  // ── Carregamento ──────────────────────────────────────────────
  carregarTudo(): void {
    this.carregando.set(true);
    const ano = this.anoAtual();
    const mes = this.mesAtual();

    // Auto-gera cobranças só para o mês atual (silenciosamente)
    if (this.ehMesAtual()) {
      this.financeiroService.gerarCobrancasMensais().subscribe({ error: () => {} });
    }

    this.financeiroService.getResumo(ano, mes).subscribe({
      next: res => { this.resumo.set(res.dados ?? null); this.carregando.set(false); },
      error: () => this.carregando.set(false),
    });

    this.financeiroService.listar({ ano, mes, pageSize: 200 }).subscribe({
      next: res => this.pagamentos.set(res.dados ?? []),
    });
  }

  selecionarAba(aba: Aba): void {
    this.abaAtiva.set(aba);
  }

  // ── Dropdown ações ────────────────────────────────────────────
  toggleDropdownAcao(id: string, event: MouseEvent): void {
    event.stopPropagation();
    if (this.dropdownAcaoId() === id) { this.dropdownAcaoId.set(null); return; }
    const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
    this.dropdownPos.set({ top: rect.bottom + 4, right: window.innerWidth - rect.right });
    this.dropdownAcaoId.set(id);
  }

  fecharDropdownAcao(): void { this.dropdownAcaoId.set(null); }

  // ── WhatsApp ──────────────────────────────────────────────────
  abrirWhatsApp(p: PagamentoDto): void {
    if (!p.telefoneAluno) return;
    const tel = p.telefoneAluno.replace(/\D/g, '');
    const nome = p.nomeAluno.split(' ')[0];
    const valor = this.formatarMoeda(p.valor);
    const venc = p.dataVencimento ? `com vencimento em ${this.formatarData(p.dataVencimento)}` : '';
    const msg = this.msgTemplate()
      .replace('{nome}', nome)
      .replace('{valor}', valor)
      .replace('{vencimento}', venc);
    window.open(`https://wa.me/55${tel}?text=${encodeURIComponent(msg)}`, '_blank');
    this.fecharDropdownAcao();
  }

  previewMsg(): string {
    return this.msgTemplateEditando()
      .replace('{nome}', 'João')
      .replace('{valor}', 'R$ 150,00')
      .replace('{vencimento}', 'com vencimento em 20/06/2025');
  }

  abrirModalMsgTemplate(): void {
    this.msgTemplateEditando.set(this.msgTemplate());
    this.modalMsgTemplate.set(true);
  }

  salvarMsgTemplate(): void {
    this.msgTemplate.set(this.msgTemplateEditando());
    this.modalMsgTemplate.set(false);
  }

  // ── Pagamentos ────────────────────────────────────────────────
  get pagamentosFiltrados(): PagamentoDto[] {
    const s = this.filtroStatus();
    return s ? this.pagamentos().filter(p => p.status === s) : this.pagamentos();
  }

  abrirModalNovoPagamento(): void {
    this.novoForm.set({ alunoId: '', tipo: 1, status: 2, valor: 0, descricao: '', dataVencimento: '', dataPagamento: '', formaPagamento: '', observacoes: '' });
    this.alunoSelecionadoNome.set('');
    this.filtroDropdownAluno.set('');
    this.erroSalvar.set('');
    this.modalNovoPagamento.set(true);
  }

  selecionarAluno(aluno: AlunoListaDto): void {
    this.novoForm.update(f => ({ ...f, alunoId: aluno.id }));
    this.alunoSelecionadoNome.set(aluno.nome);
    this.dropdownAluno.set(false);
    this.filtroDropdownAluno.set('');
  }

  updateForm(campo: string, valor: string | number): void {
    this.novoForm.update(f => ({ ...f, [campo]: valor }));
  }

  salvarPagamento(): void {
    const form = this.novoForm();
    if (!form.alunoId) { this.erroSalvar.set('Selecione um aluno.'); return; }
    if (!form.valor || form.valor <= 0) { this.erroSalvar.set('Informe um valor válido.'); return; }
    this.salvando.set(true);
    this.erroSalvar.set('');
    this.financeiroService.criar(form).subscribe({
      next: () => { this.modalNovoPagamento.set(false); this.salvando.set(false); this.carregarTudo(); },
      error: () => { this.erroSalvar.set('Erro ao salvar pagamento.'); this.salvando.set(false); },
    });
  }

  confirmarExcluir(p: PagamentoDto): void {
    this.pagamentoParaExcluir.set(p);
    this.modalExcluir.set(true);
    this.fecharDropdownAcao();
  }

  executarExcluir(): void {
    const p = this.pagamentoParaExcluir();
    if (!p) return;
    this.excluindo.set(true);
    this.financeiroService.deletar(p.id).subscribe({
      next: () => { this.modalExcluir.set(false); this.excluindo.set(false); this.pagamentoParaExcluir.set(null); this.carregarTudo(); },
      error: () => this.excluindo.set(false),
    });
  }

  marcarComoPago(p: PagamentoDto): void {
    const hoje = new Date().toISOString().split('T')[0];
    this.financeiroService.atualizar(p.id, { status: 1, dataPagamento: hoje }).subscribe({
      next: () => { this.fecharDropdownAcao(); this.carregarTudo(); },
    });
  }

  // ── Helpers ────────────────────────────────────────────────────
  formatarMoeda(valor: number): string {
    return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }

  formatarData(data?: string): string {
    if (!data) return '—';
    const [y, m, d] = data.split('-');
    return `${d}/${m}/${y}`;
  }

  badgeStatus(status: string): string {
    const map: Record<string, string> = {
      Pago: 'badge-pago', Pendente: 'badge-pendente',
      Atrasado: 'badge-atrasado', Cancelado: 'badge-cancelado',
    };
    return map[status] ?? '';
  }

  get inadimplentes(): AlunoInadimplenteDto[] {
    return this.resumo()?.inadimplentes ?? [];
  }
}
