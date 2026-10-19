import { Component, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { ConsentService } from '../../core/services/consent.service';

@Component({
  selector: 'app-privacidade',
  standalone: true,
  imports: [RouterLink],
  template: `
    <div class="legal-page">
      <div class="legal-container">
        <a routerLink="/" class="back-link">← Voltar</a>
        <h1>Política de Privacidade</h1>
        <p class="updated">Última atualização: 13 de outubro de 2026</p>

        <section>
          <h2>1. Quem somos</h2>
          <p>O <strong>Sensei Manager</strong> é uma plataforma de gestão para academias de artes marciais, desenvolvida pela Sensei Manager Tecnologia Ltda., com sede no Brasil.</p>
          <p>Esta Política de Privacidade descreve como coletamos, usamos e protegemos seus dados pessoais, em conformidade com a <strong>Lei Geral de Proteção de Dados Pessoais (LGPD — Lei nº 13.709/2018)</strong>.</p>
        </section>

        <section>
          <h2>2. Dados que coletamos</h2>
          <h3>2.1 Dados fornecidos por você</h3>
          <ul>
            <li>Nome completo, e-mail, telefone e data de nascimento</li>
            <li>Informações da academia (nome, endereço, modalidades)</li>
            <li>Dados financeiros (para gestão de mensalidades — não armazenamos dados de cartão)</li>
            <li>Documentos de saúde (atestados médicos), quando aplicável</li>
          </ul>
          <h3>2.2 Dados coletados automaticamente</h3>
          <ul>
            <li>Token de dispositivo (FCM) para envio de notificações push</li>
            <li>Logs de acesso (data/hora de login, IP)</li>
            <li>Dados de presença e frequência nas aulas</li>
          </ul>
          <h3>2.3 Cookies, armazenamento local e mensuração de campanhas</h3>
          <p>No site público do Sensei Manager (<strong>sensei-crm.web.app</strong>), usamos:</p>
          <ul>
            <li><strong>Essenciais (sempre ativos):</strong> mantêm sua sessão de login e preferências básicas do sistema. Não exigem consentimento porque o site não funciona sem eles.</li>
            <li><strong>Análise (Google Analytics), opcional:</strong> usados só com sua permissão, pra entender quantas pessoas visitam o site e quais páginas usam.</li>
            <li><strong>Publicidade (Google Ads), opcional:</strong> usados só com sua permissão, pra medir se uma campanha de anúncio resultou num cadastro.</li>
            <li><strong>Personalização, opcional:</strong> hoje não é usado para nenhum tratamento ativo — a opção existe no painel de preferências para cobrir usos futuros, caso venham a existir.</li>
          </ul>
          <p>Quando você chega ao site a partir de um link de campanha (ex.: um anúncio), podemos guardar, só com sua permissão de análise, informações sobre a origem dessa visita (de qual campanha e canal você veio) associadas à academia que você cadastrar — nunca ao seu nome, e-mail ou telefone. Essa informação fica numa área separada e restrita do nosso banco de dados, sem acesso nem pela própria equipe da academia, e é mantida por até <strong>90 dias</strong>, depois excluída automaticamente.</p>
          <p>Você escolhe suas preferências no banner que aparece na primeira visita, pode recusar tudo que for opcional, e pode mudar de ideia a qualquer momento pelo botão <button type="button" class="link-btn" (click)="consent.abrirPreferencias()">Revisar preferências de cookies</button> nesta página.</p>
        </section>

        <section>
          <h2>3. Como usamos seus dados</h2>
          <ul>
            <li>Prestar os serviços contratados (gestão de alunos, finanças, presenças)</li>
            <li>Enviar notificações sobre pagamentos, graduações e eventos da academia</li>
            <li>Cumprir obrigações legais e regulatórias</li>
            <li>Melhorar a plataforma com base em dados agregados e anonimizados</li>
          </ul>
        </section>

        <section>
          <h2>4. Compartilhamento de dados</h2>
          <p>Não vendemos seus dados pessoais. Compartilhamos apenas quando necessário com:</p>
          <ul>
            <li><strong>Prestadores de serviço</strong> (infraestrutura de nuvem, processamento de pagamentos)</li>
            <li><strong>Autoridades competentes</strong>, quando exigido por lei</li>
          </ul>
        </section>

        <section>
          <h2>5. Assinaturas — App Store e Google Play</h2>
          <p>As assinaturas do plano Sensei PRO são processadas diretamente pela Apple (App Store) ou Google (Google Play). Não temos acesso a dados de pagamento (cartão de crédito ou método de pagamento). As políticas de cobrança e reembolso seguem as diretrizes de cada loja.</p>
        </section>

        <section>
          <h2>6. Seus direitos (LGPD)</h2>
          <p>Você tem direito a:</p>
          <ul>
            <li>Confirmar a existência de tratamento dos seus dados</li>
            <li>Acessar, corrigir ou atualizar seus dados</li>
            <li>Solicitar a portabilidade ou exclusão dos seus dados</li>
            <li>Revogar o consentimento a qualquer momento</li>
          </ul>
          <p>Para exercer esses direitos, entre em contato pelo e-mail: <strong>privacidade&#64;senseimanager.com.br</strong></p>
        </section>

        <section>
          <h2>7. Segurança</h2>
          <p>Adotamos medidas técnicas e organizacionais para proteger seus dados contra acesso não autorizado, incluindo criptografia em trânsito (HTTPS/TLS) e controle de acesso baseado em perfis.</p>
        </section>

        <section>
          <h2>8. Retenção de dados</h2>
          <p>Mantemos seus dados enquanto a conta estiver ativa ou pelo tempo necessário para cumprir obrigações legais. Após solicitação de exclusão, os dados são removidos em até 30 dias, salvo obrigação legal de retenção.</p>
        </section>

        <section>
          <h2>9. Alterações nesta política</h2>
          <p>Podemos atualizar esta Política periodicamente. Notificaremos usuários sobre mudanças relevantes pelo app ou e-mail.</p>
        </section>

        <section>
          <h2>10. Contato</h2>
          <p>Dúvidas ou solicitações relacionadas à privacidade:<br>
          <strong>privacidade&#64;senseimanager.com.br</strong></p>
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
    .link-btn {
      background: none;
      border: none;
      padding: 0;
      color: #c9a020;
      text-decoration: underline;
      font: inherit;
      cursor: pointer;
    }
  `],
})
export class PrivacidadeComponent {
  readonly consent = inject(ConsentService);
}
