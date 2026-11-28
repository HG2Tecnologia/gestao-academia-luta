import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../l10n/app_localizations.dart';

/// Tela de explicação exibida ANTES de pedir qualquer dado, quando o admin
/// liga o toggle "Pagamentos pelo app" em Configurações. Devolve `true` via
/// Navigator.pop se o admin confirmar que quer continuar.
class PagamentosExplicacaoScreen extends StatelessWidget {
  const PagamentosExplicacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kText1,
        elevation: 0,
        title: Text(l.pagAppTitle, style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w700)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: kBorder)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.pagAppExplicTitle, style: TextStyle(color: kText1, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 16),
                    _passo(1, Icons.touch_app_rounded, l.pagAppExplicStep1Title, l.pagAppExplicStep1Desc),
                    const SizedBox(height: 14),
                    _passo(2, Icons.account_balance_rounded, l.pagAppExplicStep2Title, l.pagAppExplicStep2Desc),
                    const SizedBox(height: 14),
                    _passo(3, Icons.check_circle_rounded, l.pagAppExplicStep3Title, l.pagAppExplicStep3Desc),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.pagAppExplicFeesTitle, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(l.pagAppExplicFeesNote, style: TextStyle(color: kText2, fontSize: 11)),
                          const SizedBox(height: 14),
                          _taxaRow(Icons.pix_rounded, l.pagAppExplicFeePix, l.pagAppExplicFeePixValor),
                          const SizedBox(height: 10),
                          _taxaRow(Icons.receipt_long_rounded, l.pagAppExplicFeeBoleto, l.pagAppExplicFeeBoletoValor),
                          const SizedBox(height: 10),
                          _taxaRow(Icons.credit_card_rounded, l.pagAppExplicFeeCartao, l.pagAppExplicFeeCartaoValor),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kSuccess.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kSuccess.withOpacity(0.2)),
                      ),
                      child: Row(children: [
                        Icon(Icons.favorite_rounded, color: kSuccess, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(l.pagAppExplicNoCommission, style: TextStyle(color: kSuccess, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: kSurface, border: Border(top: BorderSide(color: kBorder))),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l.commonCancel, style: TextStyle(color: kText2, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(l.pagAppExplicContinuar, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passo(int numero, IconData icon, String titulo, String descricao) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: kPrimary.withOpacity(0.12), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Icon(icon, color: kPrimary, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: TextStyle(color: kText1, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(descricao, style: TextStyle(color: kText2, fontSize: 12.5, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _taxaRow(IconData icon, String titulo, String valor) {
    return Row(children: [
      Icon(icon, color: kPrimary, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(titulo, style: TextStyle(color: kText1, fontSize: 13, fontWeight: FontWeight.w600))),
      Text(valor, style: TextStyle(color: kText1, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}
