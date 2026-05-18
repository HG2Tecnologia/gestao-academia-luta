import { Component, inject, signal, OnInit, ElementRef, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { ModeloContratoService } from '../../../../core/services/modelo-contrato.service';
import { ModeloContratoDto } from '../../../../core/models/contrato.model';

const VARIAVEIS = [
  '{{nomeAluno}}', '{{email}}', '{{telefone}}', '{{dataNascimento}}',
  '{{plano}}', '{{valor}}', '{{modalidade}}',
  '{{dataInicio}}', '{{dataFim}}', '{{academia}}', '{{cnpj}}', '{{dataContrato}}',
];

const TEMPLATE_PADRAO = `<h2>Contrato de Prestação de Serviços</h2>
<p><strong>Academia:</strong> {{academia}} &nbsp;|&nbsp; <strong>CNPJ:</strong> {{cnpj}}</p>
<p><strong>Data:</strong> {{dataContrato}}</p>
<hr/>
<h3>Dados do Aluno</h3>
<p><strong>Nome:</strong> {{nomeAluno}}</p>
<p><strong>E-mail:</strong> {{email}}</p>
<p><strong>Telefone:</strong> {{telefone}}</p>
<p><strong>Data de Nascimento:</strong> {{dataNascimento}}</p>
<hr/>
<h3>Plano Contratado</h3>
<p><strong>Plano:</strong> {{plano}}</p>
<p><strong>Modalidade:</strong> {{modalidade}}</p>
<p><strong>Valor Mensal:</strong> {{valor}}</p>
<p><strong>Início:</strong> {{dataInicio}}</p>
<hr/>
<h3>Cláusulas</h3>
<p>1. O aluno se compromete a cumprir as normas internas da academia.</p>
<p>2. O pagamento da mensalidade deverá ser efetuado até o vencimento acordado.</p>
<p>3. A academia se reserva o direito de suspender o acesso em caso de inadimplência.</p>
<p>4. O cancelamento deverá ser solicitado com 30 dias de antecedência.</p>
<p>Ao assinar este contrato digitalmente, o aluno declara ter lido e concordado com todos os termos acima.</p>
<hr/>
<div style="margin-top:32px;">
  <p><strong>{{academia}}</strong></p>
  <p>CNPJ: {{cnpj}}</p>
</div>`;

@Component({
  selector: 'app-contratos-modelos',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './contratos-modelos.component.html',
})
export class ContratosModelosComponent implements OnInit {
  private readonly modeloService = inject(ModeloContratoService);

  @ViewChild('editorRef') editorRef?: ElementRef<HTMLDivElement>;

  readonly variaveis = VARIAVEIS;
  readonly carregando = signal(true);
  readonly modelos = signal<ModeloContratoDto[]>([]);
  readonly erro = signal('');

  readonly modalAberto = signal(false);
  readonly editando = signal<ModeloContratoDto | null>(null);
  readonly salvando = signal(false);
  readonly erroSalvar = signal('');
  readonly salvoOk = signal(false);

  readonly formNome = signal('');
  readonly formConteudo = signal('');

  formatText(cmd: string, value?: string): void {
    document.execCommand(cmd, false, value);
    this.syncConteudo();
  }

  syncConteudo(): void {
    if (this.editorRef) {
      this.formConteudo.set(this.editorRef.nativeElement.innerHTML);
    }
  }

  inserirVariavel(v: string): void {
    if (this.editorRef) {
      this.editorRef.nativeElement.focus();
      document.execCommand('insertText', false, v);
      this.syncConteudo();
    }
  }

  ngOnInit(): void { this.carregar(); }

  private carregar(): void {
    this.carregando.set(true);
    this.modeloService.listar().subscribe({
      next: res => { this.modelos.set(res.dados ?? []); this.carregando.set(false); },
      error: () => { this.erro.set('Erro ao carregar modelos.'); this.carregando.set(false); },
    });
  }

  abrirNovo(): void {
    this.editando.set(null);
    this.formNome.set('');
    this.formConteudo.set(TEMPLATE_PADRAO);
    this.erroSalvar.set('');
    this.salvoOk.set(false);
    this.modalAberto.set(true);
    setTimeout(() => this.preencherEditor(TEMPLATE_PADRAO), 50);
  }

  abrirEditar(m: ModeloContratoDto): void {
    this.editando.set(m);
    this.formNome.set(m.nome);
    this.formConteudo.set(m.conteudoHtml);
    this.erroSalvar.set('');
    this.salvoOk.set(false);
    this.modalAberto.set(true);
    setTimeout(() => this.preencherEditor(m.conteudoHtml), 50);
  }

  fecharModal(): void { this.modalAberto.set(false); }

  private preencherEditor(html: string): void {
    if (this.editorRef) {
      this.editorRef.nativeElement.innerHTML = html;
    }
  }

  salvar(): void {
    if (!this.formNome().trim()) { this.erroSalvar.set('Informe o nome do modelo.'); return; }
    if (!this.formConteudo().trim()) { this.erroSalvar.set('O conteúdo não pode estar vazio.'); return; }
    this.salvando.set(true);
    this.erroSalvar.set('');
    const dados = { nome: this.formNome(), conteudoHtml: this.formConteudo() };
    const req = this.editando()
      ? this.modeloService.atualizar(this.editando()!.id, dados)
      : this.modeloService.criar(dados);

    req.subscribe({
      next: res => {
        this.salvando.set(false);
        if (res.sucesso) { this.salvoOk.set(true); this.carregar(); setTimeout(() => this.fecharModal(), 900); }
        else this.erroSalvar.set(res.mensagem ?? 'Erro ao salvar.');
      },
      error: err => { this.salvando.set(false); this.erroSalvar.set(err.error?.mensagem ?? 'Erro ao salvar.'); },
    });
  }

  excluir(m: ModeloContratoDto): void {
    if (!confirm(`Excluir o modelo "${m.nome}"?`)) return;
    this.modeloService.excluir(m.id).subscribe({ next: () => this.carregar() });
  }

  formatarData(d: string): string {
    return new Date(d).toLocaleDateString('pt-BR');
  }
}
