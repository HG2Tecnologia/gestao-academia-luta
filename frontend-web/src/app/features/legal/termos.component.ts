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
        <p class="updated">Última atualização: 17 de junho de 2026</p>

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
          <h3>3.1 Plano gratuito</h3>
          <p>O plano gratuito possui limitações de alunos e funcionalidades, conforme especificado na plataforma.</p>
          <h3>3.2 Sensei PRO</h3>
          <p>O plano Sensei PRO é uma assinatura de renovação automática, disponível nos seguintes períodos:</p>
          <ul>
            <li><strong>Mensal</strong> — cobrado mensalmente</li>
            <li><strong>Trimestral</strong> — cobrado a cada 3 meses</li>
            <li><strong>Anual</strong> — cobrado anualmente</li>
          </ul>
          <p>Os preços são exibidos na tela de assinatura dentro do aplicativo, na moeda local conforme determinado pela App Store (Apple) ou Google Play (Google).</p>
          <h3>3.3 Cobrança e renovação</h3>
          <p>A cobrança é realizada pela App Store ou Google Play. A assinatura é renovada automaticamente ao final de cada período, salvo cancelamento efetuado pelo usuário com pelo menos 24 horas de antecedência do fim do período vigente.</p>
          <h3>3.4 Cancelamento</h3>
          <p>O cancelamento pode ser feito a qualquer momento nas configurações da sua conta na App Store ou Google Play. Após o cancelamento, o acesso PRO permanece ativo até o final do período pago.</p>
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
