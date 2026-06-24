import { Component, signal } from '@angular/core';

@Component({
  selector: 'app-help-widget',
  standalone: true,
  templateUrl: './help-widget.component.html',
  styleUrls: ['./help-widget.component.css'],
})
export class HelpWidgetComponent {
  readonly open = signal(false);
  readonly faqAberto = signal<number | null>(null);

  toggle(): void { this.open.update(v => !v); }
  toggleFaq(i: number): void { this.faqAberto.update(v => v === i ? null : i); }

  readonly faqs = [
    {
      q: 'Como cadastrar um novo aluno?',
      a: 'Acesse Alunos → "Novo Aluno". Preencha nome, contato, faixa e plano de pagamento. O aluno recebe acesso automático ao app.',
    },
    {
      q: 'Como lançar presença de uma turma?',
      a: 'Acesse Turmas → selecione a turma → "Lançar Presença". Marque os presentes e confirme. O ranking atualiza automaticamente.',
    },
    {
      q: 'Como emitir uma cobrança manual?',
      a: 'Vá em Financeiro → "Nova Cobrança". Selecione o aluno, valor e vencimento. O sistema envia o link de pagamento automaticamente.',
    },
    {
      q: 'Como cadastrar uma turma nova?',
      a: 'Acesse Turmas → "Nova Turma". Defina modalidade, horários, professor e capacidade máxima. Alunos podem ser vinculados depois.',
    },
    {
      q: 'Como graduar um aluno de faixa?',
      a: 'Abra o perfil do aluno → aba "Graduação" → "Registrar Graduação". Selecione a nova faixa e data. O histórico fica salvo permanentemente.',
    },
    {
      q: 'Como ver alunos inadimplentes?',
      a: 'No Dashboard ou em Financeiro → filtro "Inadimplentes". Você vê quem deve, há quanto tempo e pode cobrar com um clique.',
    },
    {
      q: 'Como funciona o controle de catraca?',
      a: 'Acesse Catraca → configure o dispositivo com o código gerado. A catraca libera automaticamente para alunos com pagamento em dia.',
    },
    {
      q: 'Como gerar um relatório?',
      a: 'Acesse Relatórios → escolha o tipo (presença, financeiro, inadimplência). Configure o período e exporte em PDF ou Excel.',
    },
    {
      q: 'Como configurar o Pix automático?',
      a: 'Em Configurações → Financeiro → adicione sua chave Pix. As cobranças passam a ser geradas e enviadas automaticamente no vencimento.',
    },
    {
      q: 'Como alterar o plano da academia?',
      a: 'Em Configurações → "Plano da Academia". O upgrade também pode ser feito pelo app mobile — reflete aqui instantaneamente.',
    },
  ];
}
