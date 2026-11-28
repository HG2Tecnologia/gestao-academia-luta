import { Injectable, inject } from '@angular/core';
import { collection, getDocs, query, where } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';
import { db, functions } from '../firebase/firebase';
import { FirebaseAuthService } from './firebase-auth.service';
import { DialogService } from './dialog.service';

export type ColecaoPerfil = 'usuarios' | 'funcionarios';
export type MotivoAcesso = 'provisao_criacao' | 'provisao_edicao' | 'redefinicao';
export type ResolucaoConflito = 'manterAtual' | 'gerarNova';

export interface PedidoAcesso {
  colecao: ColecaoPerfil;
  usuarioId: string;
  nome: string;
  motivo: MotivoAcesso;
  confirmarSobrescrita?: boolean;
  apenasVincular?: boolean;
}

interface RespostaAcesso {
  temporaryPassword?: string;
  nome?: string;
  loginHint?: string;
  vinculadoSemSenha?: boolean;
}

/**
 * Espelho de `mobile/lib/core/senha_temporaria_modal.dart`: provisiona ou
 * redefine o acesso de um cadastro e mostra a senha temporária pra academia
 * repassar. Os textos são os mesmos do app.
 */
@Injectable({ providedIn: 'root' })
export class AcessoService {
  private readonly authService = inject(FirebaseAuthService);
  private readonly dialog = inject(DialogService);

  private get academiaId(): string {
    const id = this.authService.currentUser()?.academiaId;
    if (!id) throw new Error('Sem academia associada à sessão atual.');
    return id;
  }

  /** Devolve `true` se o acesso foi gerado/vinculado e mostrado. */
  async gerarEMostrar(pedido: PedidoAcesso): Promise<boolean> {
    try {
      const chamar = httpsCallable(functions, 'adminResetPassword');
      const { data } = await chamar({
        academiaId: this.academiaId,
        colecao: pedido.colecao,
        usuarioId: pedido.usuarioId,
        motivo: pedido.motivo,
        confirmarSobrescrita: pedido.confirmarSobrescrita === true,
        apenasVincular: pedido.apenasVincular === true,
      });
      const resposta = data as RespostaAcesso;
      const nome = resposta.nome || pedido.nome;
      const comoEntrar = resposta.loginHint ? `o ${resposta.loginHint}` : 'o telefone ou e-mail cadastrado';

      if (resposta.vinculadoSemSenha) {
        await this.dialog.alert(
          `${nome} vai acessar o app com ${comoEntrar} e a senha que já foi definida por quem usa esse contato. Nenhuma senha nova foi gerada.`,
          { titulo: 'Vinculado', textoConfirmar: 'Entendi' },
        );
        return true;
      }
      await this.mostrarSenha(nome, resposta.temporaryPassword ?? '', comoEntrar);
      return true;
    } catch (erro: any) {
      if (erro?.details?.code === 'senha_ja_definida') {
        const escolha = await this.perguntarConflito(pedido.nome);
        if (!escolha) return false;
        return this.gerarEMostrar({
          ...pedido,
          confirmarSobrescrita: escolha === 'gerarNova',
          apenasVincular: escolha === 'manterAtual',
        });
      }
      const prefixo = pedido.motivo === 'redefinicao'
        ? 'Não foi possível redefinir a senha'
        : 'Não foi possível gerar a senha de acesso';
      await this.dialog.alert(`${prefixo}: ${erro?.message ?? 'erro desconhecido'}`);
      return false;
    }
  }

  mostrarSenha(nome: string, senha: string, comoEntrar = 'o telefone ou e-mail cadastrado'): Promise<void> {
    return this.dialog.alert(
      `Copie agora e repasse para ${nome}. Para entrar, use ${comoEntrar} e esta senha temporária. ` +
        'Em seguida será pedido para criar a senha definitiva.',
      {
        titulo: `Senha temporária de ${nome}`,
        textoConfirmar: 'Entendi',
        copiavel: senha,
        textoParaCopiar:
          `Sensei Manager — acesso de ${nome}\nEntre com ${comoEntrar} e a senha temporária: ${senha}\n` +
          'Será pedido para criar a sua senha definitiva.',
      },
    );
  }

  async redefinir(colecao: ColecaoPerfil, usuarioId: string, nome: string): Promise<boolean> {
    const ok = await this.dialog.confirm(
      'Uma nova senha temporária será gerada e a sessão atual dessa pessoa será encerrada. Ela precisará usar a senha temporária para entrar e trocar por uma senha definitiva.',
      { titulo: `Redefinir senha de ${nome}?`, textoConfirmar: 'Redefinir' },
    );
    return ok ? this.gerarEMostrar({ colecao, usuarioId, nome, motivo: 'redefinicao' }) : false;
  }

  async perguntarConflito(nome: string): Promise<ResolucaoConflito | null> {
    const escolha = await this.dialog.escolher(
      `Já existe outro cadastro com o mesmo telefone/e-mail de ${nome}, e essa pessoa já entrou no app e definiu a própria senha.\n\n` +
        `• Manter a senha atual: ${nome} vai acessar com a mesma senha que essa pessoa já definiu — nada muda para quem já usa o app.\n` +
        '• Gerar nova senha temporária: substitui o acesso de todo mundo que usa esse telefone/e-mail. Quem já tinha senha própria vai precisar defini-la de novo no próximo login.',
      {
        titulo: 'Esse telefone ou e-mail já está em uso',
        textoConfirmar: 'Gerar nova temporária',
        textoAlternativo: 'Manter senha atual',
      },
    );
    if (escolha === 'cancelar') return null;
    return escolha === 'confirmar' ? 'gerarNova' : 'manterAtual';
  }

  /** Checagem prévia, antes de criar o cadastro — cancelar aqui não deixa nada pela metade. */
  async contatoJaTemSenha(telefone: string, email: string): Promise<boolean> {
    const chamar = httpsCallable(functions, 'checkContatoCompartilhado');
    const { data } = await chamar({ academiaId: this.academiaId, telefone, email });
    return (data as { conflito?: boolean }).conflito === true;
  }

  /** Cadastro de outra coleção que já usa este telefone (professor que também é aluno e vice-versa). */
  async perfilComMesmoTelefone(
    colecao: ColecaoPerfil,
    telefone: string,
  ): Promise<{ nome: string; perfil: string } | null> {
    const digitos = telefone.replace(/\D/g, '');
    if (!digitos) return null;
    const ref = collection(db, 'academias', this.academiaId, colecao);
    const consultas = await Promise.all([
      getDocs(query(ref, where('telefone_digits', '==', digitos))),
      getDocs(query(ref, where('telefone', '==', telefone.trim()))),
    ]);
    const achado = consultas
      .flatMap((s) => s.docs.map((d) => d.data()))
      .find((d) => colecao !== 'usuarios' || d['perfil'] === 3);
    if (!achado) return null;
    const perfil = colecao === 'usuarios' ? 'Aluno' : String(achado['perfil_nome'] ?? 'Professor');
    return { nome: String(achado['nome'] ?? ''), perfil };
  }
}
