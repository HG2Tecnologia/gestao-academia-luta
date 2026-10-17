import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/paywall_modal.dart';
import '../../core/plan_service.dart';
import '../../core/theme/context_ext.dart';
import '../../l10n/app_localizations.dart';

class PlanoScreen extends StatefulWidget {
  const PlanoScreen({super.key});

  @override
  State<PlanoScreen> createState() => _PlanoScreenState();
}

class _PlanoScreenState extends State<PlanoScreen> {
  AppLocalizations get _l => context.l10n;

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _trocarDePlano() async {
    final ok = await mostrarPaywall(context);
    if (ok == true) {
      await PlanService.instance.refresh();
      if (mounted) setState(() {});
    }
  }

  Future<void> _cancelarAssinatura() async {
    final plan = PlanService.instance;
    final plataforma = plan.planoPlataforma;
    final isIOS = plataforma == 'ios' || (plataforma == null && !kIsWeb && Platform.isIOS);

    final uri = isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse(
            'https://play.google.com/store/account/subscriptions'
            '?package=$kAppPackageId'
            '${plan.planoProdutoId != null ? '&sku=${plan.planoProdutoId}' : ''}',
          );

    final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_l.planCancelError),
          backgroundColor: context.sem.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = PlanService.instance;
    final produtoNome = planoProdutoDisplayName(plan.planoProdutoId);
    final expiracao = plan.planoExpiracao;
    final assinadoEm = plan.planoAssinadoEm;
    final plataforma = plan.planoPlataforma;

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surfaceContainer,
        foregroundColor: context.c.onSurface,
        elevation: 0,
        title: Text(
          _l.planTitle,
          style: TextStyle(color: context.c.onSurface, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.c.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF6C3FFF).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD700),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        produtoNome != null ? 'Sensei PRO · $produtoNome' : 'Sensei PRO',
                        style: TextStyle(
                          color: context.c.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _l.cfgPlanActive,
                        style: TextStyle(color: context.sem.success, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: context.c.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.c.outline),
            ),
            child: Column(
              children: [
                if (assinadoEm != null)
                  _InfoRow(
                    icon: Icons.event_available_rounded,
                    label: _l.planSubscribedSince,
                    value: _formatarData(assinadoEm),
                  ),
                if (assinadoEm != null && expiracao != null)
                  Divider(height: 1, color: context.c.outline),
                if (expiracao != null)
                  _InfoRow(
                    icon: Icons.autorenew_rounded,
                    label: _l.planRenewsOn,
                    value: _formatarData(expiracao),
                    hint: _l.planRenewsOnHint,
                  ),
                if (plataforma == 'ios' || plataforma == 'android') ...[
                  Divider(height: 1, color: context.c.outline),
                  _InfoRow(
                    icon: plataforma == 'ios'
                        ? Icons.phone_iphone_rounded
                        : Icons.android_rounded,
                    label: plataforma == 'ios' ? _l.planViaAppStore : _l.planViaPlayStore,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _trocarDePlano,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(_l.planChangePlan),
            style: FilledButton.styleFrom(
              backgroundColor: context.c.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _cancelarAssinatura,
            icon: Icon(Icons.cancel_outlined, color: context.sem.danger),
            label: Text(
              _l.planCancelSubscription,
              style: TextStyle(color: context.sem.danger),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.sem.danger.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _l.planCancelHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? hint;

  const _InfoRow({required this.icon, required this.label, this.value, this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.c.onSurfaceVariant, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 12.5),
                ),
                if (hint != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    hint!,
                    style: TextStyle(color: context.c.onSurfaceVariant, fontSize: 10.5),
                  ),
                ],
              ],
            ),
          ),
          if (value != null)
            Text(
              value!,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
