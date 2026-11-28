import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';
import 'theme/context_ext.dart';

/// Rodapé discreto com a versão instalada do app ("Versão 1.4.3 (33)").
/// Tocar copia o texto — o usuário cola no suporte quando pedimos a versão.
class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final info = snap.data;
        if (info == null) return const SizedBox(height: 24);
        final l = AppLocalizations.of(context);
        final texto = l.appVersionLabel(info.version, info.buildNumber);
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: texto));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l.appVersionCopied),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: Center(
              child: Text(
                'Sensei · $texto',
                style: TextStyle(
                  color: context.c.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
