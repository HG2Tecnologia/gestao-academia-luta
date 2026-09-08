import 'package:flutter/material.dart';
import '../../core/constants.dart';

enum MetodoPagamento { pix, boleto, cartao }

class PagamentoMetodoSheet extends StatelessWidget {
  const PagamentoMetodoSheet({super.key});

  static Future<MetodoPagamento?> show(BuildContext context) {
    return showModalBottomSheet<MetodoPagamento>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const PagamentoMetodoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Como deseja pagar?', style: TextStyle(color: kText1, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Escolha o método de pagamento', style: TextStyle(color: kText2, fontSize: 13)),
              const SizedBox(height: 24),
              _metodoTile(
                context,
                icon: Icons.pix_rounded,
                color: const Color(0xFF32BCAD),
                titulo: 'PIX',
                subtitulo: 'Aprovação imediata • 24h por dia',
                metodo: MetodoPagamento.pix,
              ),
              const SizedBox(height: 12),
              _metodoTile(
                context,
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF1976D2),
                titulo: 'Boleto Bancário',
                subtitulo: 'Compensa em até 3 dias úteis',
                metodo: MetodoPagamento.boleto,
              ),
              const SizedBox(height: 12),
              _metodoTile(
                context,
                icon: Icons.credit_card_rounded,
                color: const Color(0xFF7B1FA2),
                titulo: 'Cartão de Crédito',
                subtitulo: 'À vista no cartão',
                metodo: MetodoPagamento.cartao,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metodoTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String titulo,
    required String subtitulo,
    required MetodoPagamento metodo,
  }) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(metodo),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: TextStyle(color: kText1, fontSize: 15, fontWeight: FontWeight.w700)),
                  Text(subtitulo, style: TextStyle(color: kText2, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: kText2.withOpacity(0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
