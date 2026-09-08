import 'package:flutter/material.dart';
import '../constants.dart';

/// Design tokens da área do aluno.
///
/// Centraliza espaçamento, raio, tipografia e cores semânticas para que as
/// telas parem de repetir literais. As cores continuam vindo de
/// [constants.dart] (identidade Sensei Manager: preto + dourado) — aqui só
/// damos nomes semânticos e apelidos estáveis.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  /// Margem lateral padrão das telas do aluno.
  static const double screenH = 16;

  /// Espaço mínimo de toque acessível (Material / WCAG).
  static const double minTouch = 48;
}

abstract final class AppRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double pill = 999;

  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
}

/// Paleta semântica. Mantém os apelidos `k*` como fonte, só reexpõe com
/// nomes de papel para leitura das telas novas.
abstract final class AppColors {
  static const Color bg = kBg;
  static const Color surface = kSurface;
  static const Color border = kBorder;
  static const Color primary = kPrimary;
  static const Color textPrimary = kText1;
  static const Color textSecondary = kText2;
  static const Color success = kSuccess;
  static const Color warning = kWarning;
  static const Color danger = kDanger;

  /// Azul semântico — informação / turmas.
  static const Color info = Color(0xFF0EA5E9);

  /// Fallback neutro para graduações sem cor cadastrada — NUNCA usar a cor
  /// da marca aqui, senão faixa "sem cor" aparece dourada.
  static const Color graduationNeutral = Color(0xFF3A3A3A);
}

abstract final class AppText {
  static const TextStyle screenTitle = TextStyle(
    color: kText1,
    fontSize: 26,
    fontWeight: FontWeight.w900,
  );
  static const TextStyle screenSubtitle = TextStyle(
    color: kText2,
    fontSize: 13,
  );
  static const TextStyle sectionLabel = TextStyle(
    color: kText2,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );
  static const TextStyle cardTitle = TextStyle(
    color: kText1,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle body = TextStyle(color: kText1, fontSize: 14);
  static const TextStyle bodyMuted = TextStyle(color: kText2, fontSize: 13);
  static const TextStyle caption = TextStyle(color: kText2, fontSize: 12);
}
