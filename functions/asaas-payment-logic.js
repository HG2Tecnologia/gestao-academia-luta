'use strict';

const admin = require('firebase-admin');

/**
 * Processa um evento de webhook Asaas e atualiza o Firestore.
 * db e messaging são injetados para permitir testes unitários sem emulador.
 *
 * @returns {{ ok: boolean, action: string, academiaId?: string, pagamentoId?: string }}
 */
async function processWebhookEvent({ event, payment }, db, messaging) {
  const ref = payment?.externalReference || '';
  const parts = ref.split(':');
  if (parts.length !== 2) return { ok: true, action: 'ignored' };

  const [academiaId, pagamentoId] = parts;
  const pagRef = db.doc(`academias/${academiaId}/pagamentos/${pagamentoId}`);

  if (event === 'PAYMENT_RECEIVED' || event === 'PAYMENT_CONFIRMED') {
    const updatePayload = {
      status: 1,
      asaasStatus: 'RECEIVED',
      pago_em: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (payment?.id) updatePayload.asaasChargeId = payment.id;
    await pagRef.update(updatePayload).catch(() => {});

    try {
      const valor = payment?.value;
      const descricao = payment?.description || 'Mensalidade';
      const valorFmt = valor != null
        ? `R$ ${Number(valor).toFixed(2).replace('.', ',')}`
        : '';
      const bt = payment?.billingType || 'PIX';
      const metodoLabel = bt === 'BOLETO' ? 'Boleto' : bt === 'CREDIT_CARD' ? 'Cartão' : 'PIX';

      const funcionariosSnap = await db
        .collection('academias').doc(academiaId)
        .collection('funcionarios')
        .where('perfil', 'in', ['Admin', 'Secretaria'])
        .get();

      const tokens = [];
      funcionariosSnap.forEach((f) => {
        const d = f.data();
        if (Array.isArray(d.fcm_tokens)) tokens.push(...d.fcm_tokens);
      });

      // ID determinístico garante idempotência em retentativas do webhook
      await db.collection('academias').doc(academiaId).collection('notificacoes')
        .doc(`pago-${pagamentoId}`)
        .set({
          titulo: `Pagamento recebido${valorFmt ? ` — ${valorFmt}` : ''}`,
          mensagem: `${metodoLabel}: ${descricao}`,
          tipo: 'sucesso',
          lida: false,
          chave_dedup: `pago-${pagamentoId}`,
          criado_em: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

      if (tokens.length > 0 && messaging) {
        await messaging.sendEachForMulticast({
          tokens,
          notification: {
            title: `Pagamento ${metodoLabel} recebido${valorFmt ? ` — ${valorFmt}` : ''}`,
            body: descricao,
          },
          data: { tipo: `pagamento_${bt.toLowerCase()}`, academiaId, pagamentoId },
        });
      }
    } catch (_) { /* push/notif é best-effort */ }

    return { ok: true, action: 'paid', academiaId, pagamentoId };
  }

  if (event === 'PAYMENT_OVERDUE') {
    await pagRef.update({ status: 2, asaasStatus: 'OVERDUE' }).catch(() => {});
    return { ok: true, action: 'overdue', academiaId, pagamentoId };
  }

  return { ok: true, action: 'ignored' };
}

/**
 * Sincroniza pagamentos PENDING e OVERDUE de uma academia com o status real no Asaas.
 * db e makeAsaasClient são injetados para testes.
 *
 * makeAsaasClient(walletId) deve retornar um cliente axios-like com .get(url).
 *
 * @returns {{ sincronizados: number }}
 */
async function sincronizarPagamentosAcademia(academiaId, alunoId, db, makeAsaasClient) {
  const cfgSnap = await db.doc(`academias/${academiaId}/integracoes/asaas`).get();
  const cfgData = cfgSnap.data();
  if (!cfgSnap.exists || !cfgData?.subcontaId) {
    return { sincronizados: 0 };
  }

  const { subcontaId } = cfgData;
  let walletId = cfgData.walletId || null;

  if (!walletId) {
    try {
      const masterClient = makeAsaasClient(null);
      const accRes = await masterClient.get(`/accounts/${subcontaId}`);
      walletId = accRes.data?.walletId || null;
      if (walletId) {
        await db.doc(`academias/${academiaId}/integracoes/asaas`).update({ walletId });
      }
    } catch (_) { /* best-effort */ }
  }

  const client = makeAsaasClient(walletId);

  const [snapPending, snapOverdue] = await Promise.all([
    db.collection(`academias/${academiaId}/pagamentos`).where('asaasStatus', '==', 'PENDING').get(),
    db.collection(`academias/${academiaId}/pagamentos`).where('asaasStatus', '==', 'OVERDUE').get(),
  ]);
  const allDocs = [...snapPending.docs, ...snapOverdue.docs];

  let sincronizados = 0;

  for (const doc of allDocs) {
    const pag = doc.data();
    if (!pag.asaasChargeId) continue;
    if (alunoId && pag.aluno_id !== alunoId) continue;

    try {
      let asaasStatus;
      let foundChargeId = pag.asaasChargeId;

      // Tentativa 1: busca direta pelo chargeId
      try {
        const r = await client.get(`/payments/${pag.asaasChargeId}`);
        asaasStatus = r.data.status;
      } catch (e) {
        // Tentativa 2: fallback por externalReference (charge pode ter sido recriado)
        const externalRef = `${academiaId}:${doc.id}`;
        let allPayments = [];
        try {
          const r2 = await client.get(`/payments?externalReference=${encodeURIComponent(externalRef)}&limit=20`);
          allPayments = r2.data?.data || [];
        } catch (_) {}

        // Tentativa 3: master sem walletId (charge criado sem wallet header)
        if (allPayments.length === 0) {
          const masterClient = makeAsaasClient(null);
          try {
            const r3 = await masterClient.get(`/payments/${pag.asaasChargeId}`);
            asaasStatus = r3.data.status;
          } catch (_) {
            try {
              const sr3 = await masterClient.get(`/payments?externalReference=${encodeURIComponent(externalRef)}&limit=20`);
              allPayments = sr3.data?.data || [];
            } catch (_) {}
          }
        }

        if (!asaasStatus) {
          const confirmed = allPayments.find((p) => p.status === 'RECEIVED' || p.status === 'CONFIRMED');
          if (confirmed) {
            asaasStatus = confirmed.status;
            foundChargeId = confirmed.id;
          } else if (allPayments.length > 0) {
            asaasStatus = allPayments[0].status;
            foundChargeId = allPayments[0].id;
          } else {
            continue; // não encontrado em nenhuma tentativa
          }
        }
      }

      if (asaasStatus === 'RECEIVED' || asaasStatus === 'CONFIRMED') {
        await doc.ref.update({
          status: 1,
          asaasStatus: 'RECEIVED',
          asaasChargeId: foundChargeId,
          pago_em: admin.firestore.FieldValue.serverTimestamp(),
        });
        sincronizados++;
      } else if (asaasStatus === 'OVERDUE') {
        await doc.ref.update({ status: 2, asaasStatus: 'OVERDUE' });
      }
    } catch (_) { /* erro num doc não para o loop */ }
  }

  return { sincronizados };
}

module.exports = { processWebhookEvent, sincronizarPagamentosAcademia };
