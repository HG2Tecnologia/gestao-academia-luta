import 'package:flutter/material.dart';

/// Ícone de faixa de artes marciais (faixa + nó + pontas), desenhado à mão.
/// Comporta-se como um [Icon]: herda tamanho/cor do [IconTheme] quando não são
/// passados — assim funciona dentro da NavigationBar (a seleção troca a cor
/// sozinha).
class BeltIcon extends StatelessWidget {
  final double? size;
  final Color? color;

  const BeltIcon({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final s = size ?? iconTheme.size ?? 24.0;
    final c =
        color ??
        iconTheme.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black);
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(painter: _BeltPainter(c)),
    );
  }
}

class _BeltPainter extends CustomPainter {
  final Color color;
  const _BeltPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(s * 0.5, s * 0.5);

    // As quatro pontas da faixa amarrada: duas dão a volta na cintura (para
    // cima e para os lados) e duas ficam penduradas (tirando o nó).
    final strap = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.17
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    void ponta(Offset from, Offset to) => canvas.drawLine(from, to, strap);

    ponta(Offset(s * 0.45, s * 0.47), Offset(s * 0.05, s * 0.27)); // cintura ↖
    ponta(Offset(s * 0.55, s * 0.47), Offset(s * 0.95, s * 0.27)); // cintura ↗
    ponta(Offset(s * 0.47, s * 0.55), Offset(s * 0.29, s * 0.97)); // ponta ↙
    ponta(Offset(s * 0.53, s * 0.55), Offset(s * 0.71, s * 0.97)); // ponta ↘

    // Nó central, por cima das pontas, levemente girado.
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: s * 0.36, height: s * 0.30),
        Radius.circular(s * 0.06),
      ),
      fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BeltPainter old) => old.color != color;
}
