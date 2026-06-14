import 'dart:io';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_client.dart';
import 'constants.dart';

class VersionCheckService {
  static Future<void> check(BuildContext context) async {
    try {
      final res = await dio.get('/api/version');
      final data = res.data as Map<String, dynamic>;
      final minVersion = data['minVersion']?.toString() ?? '0.0.0';
      final currentVersion = data['currentVersion']?.toString() ?? '0.0.0';
      final forceUpdate = data['forceUpdate'] == true;
      final storeUrl = Platform.isIOS
          ? data['iosUrl']?.toString() ?? ''
          : data['androidUrl']?.toString() ?? '';

      final info = await PackageInfo.fromPlatform();
      final appVersion = info.version;

      if (!context.mounted) return;

      final belowMin = _compare(appVersion, minVersion) < 0;
      final belowCurrent = _compare(appVersion, currentVersion) < 0;

      if (belowMin || forceUpdate) {
        await _showDialog(context, storeUrl, forced: true);
      } else if (belowCurrent) {
        await _showDialog(context, storeUrl, forced: false);
      }
    } catch (_) {
      // Não bloqueia o app se o servidor estiver fora ou sem conexão
    }
  }

  static Future<void> _showDialog(
    BuildContext context,
    String storeUrl, {
    required bool forced,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: !forced,
      builder: (ctx) => PopScope(
        canPop: !forced,
        child: AlertDialog(
          backgroundColor: kSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.system_update_rounded, color: kPrimary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  forced ? 'Atualização obrigatória' : 'Nova versão disponível',
                  style: TextStyle(color: kText1, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Text(
            forced
                ? 'Esta versão do app está muito desatualizada. Atualize para continuar usando o Sensei Manager.'
                : 'Uma nova versão do Sensei Manager está disponível com melhorias e correções. Recomendamos atualizar.',
            style: TextStyle(color: kText2, fontSize: 13, height: 1.5),
          ),
          actions: [
            if (!forced)
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Agora não', style: TextStyle(color: kText2, fontSize: 13)),
              ),
            FilledButton(
              onPressed: storeUrl.isNotEmpty
                  ? () async {
                      final uri = Uri.parse(storeUrl);
                      if (await canLaunchUrl(uri)) {
                        launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Atualizar agora', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // Retorna negativo se a < b, 0 se igual, positivo se a > b
  static int _compare(String a, String b) {
    final pa = a.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    final pb = b.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }
}
