import { Component } from '@angular/core';
import { RouterLink } from '@angular/router';

@Component({
  selector: 'app-termos',
  standalone: true,
  imports: [RouterLink],
  template: `
    <div class="legal-page">
      <div class="legal-container">
        <a routerLink="/" class="back-link">← Voltar</a>
        <h1>Termos de Uso</h1>
        <p class="updated">Última atualização: 26 de novembro de 2026</p>

        <section>
          <h2>1. Aceitação dos termos</h2>
          <p>Ao criar uma conta ou usar os serviços do <strong>Sensei Manager</strong>, você concorda com estes Termos de Uso. Se não concordar, não utilize o serviço.</p>
        </section>

        <section>
          <h2>2. Descrição do serviço</h2>
          <p>O Sensei Manager é uma plataforma SaaS de gestão para academias de artes marciais. Oferecemos funcionalidades de gestão de alunos, controle de presença, gestão financeira, ranking gamificado, contratos digitais e aplicativo móvel para alunos e professores.</p>
        </section>

        <section>
          <h2>3. Planos e assinaturas</h2>
          <h3>3.1 Período de teste</h3>
          <p>Toda academia nova tem 30 dias de teste, a partir do cadastro, com todos os recursos liberados, inclusive o sistema web, sem necessidade de cartão. O prazo vigente é o informado no cadastro.</p>
          <h3>3.2 Plano gratuito</h3>
          <p>Após o teste, o plano gratuito é limitado a 5 alunos ativos, 1 turma ativa e 1 funcionário, exibe anúncios no aplicativo, não inclui recursos exclusivos dos planos pagos nem o acesso ao sistema web. Cadastros feitos além desses limites durante o teste são mantidos, mas não é possível incluir novos enquanto o limite estiver excedido.</p>
          <h3>3.3 Planos pagos</h3>
          <p>Os planos pagos são assinaturas de renovação automática, contratadas por academia, nos períodos mensal, trimestral (cobrado a cada 3 meses) e anual:</p>
          <ul>
            <li><strong>Sensei PRO</strong> — recursos do aplicativo sem os limites do plano gratuito. Não inclui o sistema web.</li>
            <li><strong>Sensei Black Belt</strong> — tudo do Sensei PRO e o acesso ao sistema web.</li>
          </ul>
          <p>Cada academia mantém um plano pago por vez. Os preços são exibidos na tela de assinatura do aplicativo, na moeda local, conforme a App Store (Apple) ou o Google Play (Google).</p>
          <h3>3.4 Cobrança, troca de plano e cancelamento</h3>
          <p>A cobrança é realizada pela App Store ou pelo Google Play. A assinatura é renovada automaticamente ao final de cada período, salvo cancelamento feito com pelo menos 24 horas de antecedência do fim do período vigente. A troca de plano é feita pela loja em que a assinatura foi contratada: a passagem para um plano superior vale de imediato, e a passagem para um plano inferior ou a mudança de período valem a partir da renovação, conforme as regras da loja.</p>
          <p>O cancelamento pode ser feito a qualquer momento nas assinaturas da sua conta na App Store ou no Google Play. Depois dele, o acesso pago permanece até o fim do período já pago. Se uma cobrança não for aprovada, o acesso pago pode ser suspenso até a regularização do pagamento.</p>
          <h3>3.5 Reembolsos</h3>
          <p>Políticas de reembolso seguem as diretrizes da Apple (App Store) e Google (Google Play), conforme aplicável.</p>
        </section>

        <section>
          <h2>4. Obrigações do usuário</h2>
          <p>Ao usar o Sensei Manager, você se compromete a:</p>
          <ul>
            <li>Fornecer informações verdadeiras e atualizadas no cadastro</li>
            <li>Não compartilhar suas credenciais de acesso com terceiros</li>
            <li>Não utilizar a plataforma para fins ilegais ou não autorizados</li>
            <li>Cumprir todas as leis aplicáveis, incluindo a LGPD no tratamento de dados de alunos</li>
            <li>Obter consentimento adequado dos alunos para coleta e tratamento de dados pessoais</li>
          </ul>
        </section>

        <section>
          <h2>5. Propriedade intelectual</h2>
          <p>Todos os direitos sobre a plataforma, código, design, marcas e conteúdo pertencem ao Sensei Manager. O uso da plataforma não transfere qualquer direito de propriedade intelectual ao usuário.</p>
        </section>

        <section>
          <h2>6. Limitação de responsabilidade</h2>
          <p>O Sensei Manager não se responsabiliza por:</p>
          <ul>
            <li>Perdas financeiras decorrentes do uso inadequado da plataforma</li>
            <li>Interrupções temporárias do serviço por manutenção ou força maior</li>
            <li>Dados inseridos incorretamente pelo usuário</li>
          </ul>
        </section>

        <section>
          <h2>7. Disponibilidade do serviço</h2>
          <p>Nos esforçamos para manter o serviço disponível 24/7, mas não garantimos disponibilidade ininterrupta. Manutenções programadas serão comunicadas com antecedência quando possível.</p>
        </section>

        <section>
          <h2>8. Rescisão</h2>
          <p>Reservamos o direito de suspender ou encerrar contas que violem estes Termos, sem aviso prévio em casos graves. Em caso de encerramento por nossa parte sem justa causa, o período pago remanescente será reembolsado.</p>
        </section>

        <section>
          <h2>9. Alterações nos termos</h2>
          <p>Podemos modificar estes Termos a qualquer momento. O uso contínuo da plataforma após notificação de mudança constitui aceite dos novos termos.</p>
        </section>

        <section>
          <h2>10. Lei aplicável e foro</h2>
          <p>Estes Termos são regidos pelas leis brasileiras. Fica eleito o foro da comarca de São Paulo/SP para dirimir quaisquer controvérsias.</p>
        </section>

        <section>
          <h2>11. Contato</h2>
          <p>Dúvidas sobre estes Termos:<br>
          <strong>suporte&#64;senseimanager.com.br</strong></p>
        </section>
      </div>
    </div>
  `,
  styles: [`
    .legal-page {
      min-height: 100vh;
      background: #0f172a;
      color: #f8fafc;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      padding: 40px 16px 80px;
    }
    .legal-container {
      max-width: 780px;
      margin: 0 auto;
    }
    .back-link {
      display: inline-block;
      color: #c9a020;
      text-decoration: none;
      font-size: 14px;
      margin-bottom: 32px;
    }
    h1 {
      font-size: 32px;
      font-weight: 800;
      margin-bottom: 8px;
    }
    .updated {
      color: #94a3b8;
      font-size: 13px;
      margin-bottom: 40px;
    }
    section {
      margin-bottom: 32px;
    }
    h2 {
      font-size: 18px;
      font-weight: 700;
      color: #c9a020;
      margin-bottom: 12px;
      margin-top: 0;
    }
    h3 {
      font-size: 15px;
      font-weight: 600;
      color: #e2e8f0;
      margin: 12px 0 8px;
    }
    p {
      color: #cbd5e1;
      line-height: 1.7;
      margin: 0 0 12px;
    }
    ul {
      color: #cbd5e1;
      line-height: 1.7;
      padding-left: 20px;
      margin: 0 0 12px;
    }
    li { margin-bottom: 4px; }
    strong { color: #f1f5f9; }
  `],
})
export class TermosComponent {}
