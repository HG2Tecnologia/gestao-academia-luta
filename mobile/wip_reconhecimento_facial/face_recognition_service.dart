import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Um rosto detectado numa foto, já com seu embedding calculado (ou `null`
/// se o embedding não pôde ser gerado, ex.: recorte vazio).
class DetectedFace {
  DetectedFace({required this.boundingBox, required this.embedding});

  /// Posição do rosto na foto original, em pixels — usada só pra desenhar a
  /// caixinha na UI de revisão, não entra no cálculo de similaridade.
  final FaceBoundingBox boundingBox;
  final List<double>? embedding;
}

class FaceBoundingBox {
  FaceBoundingBox(this.left, this.top, this.width, this.height);
  final double left;
  final double top;
  final double width;
  final double height;
}

/// Reconhecimento facial 100% local (nenhuma chamada de rede): detecção via
/// Google ML Kit, embedding via FaceNet (TFLite, Apache-2.0 — ver
/// assets/ml/NOTICE.txt). Modelo espera entrada 160x160 RGB, normalizada por
/// padronização por imagem (x-média)/desvio, igual ao pipeline original do
/// modelo (FaceNetModel.kt do repositório de origem).
abstract final class FaceRecognitionService {
  static const int _inputSize = 160;
  static const double _matchThreshold = 0.62;

  static Interpreter? _interpreter;
  static FaceDetector? _detector;

  static Future<Interpreter> _getInterpreter() async {
    return _interpreter ??= await Interpreter.fromAsset(
      'assets/ml/facenet.tflite',
    );
  }

  static FaceDetector _getDetector() {
    return _detector ??= FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
    );
  }

  /// Libera os recursos do modelo/detector (ex.: ao saber que a feature foi
  /// desligada ou a tela de chamada por foto foi fechada por um tempo longo).
  static Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
    _interpreter?.close();
    _interpreter = null;
  }

  /// Detecta todos os rostos numa foto de arquivo e já calcula o embedding
  /// de cada um. Usado na "chamada por foto" (grupo de alunos).
  static Future<List<DetectedFace>> detectFacesInFile(String path) async {
    await _getInterpreter();
    final bytes = await File(path).readAsBytes();
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return const [];
    decoded = img.bakeOrientation(decoded);

    final inputImage = InputImage.fromFilePath(path);
    final faces = await _getDetector().processImage(inputImage);

    final resultado = <DetectedFace>[];
    for (final face in faces) {
      final box = face.boundingBox;
      final embedding = _embedCrop(decoded, box.left, box.top, box.width, box.height);
      resultado.add(
        DetectedFace(
          boundingBox: FaceBoundingBox(box.left, box.top, box.width, box.height),
          embedding: embedding,
        ),
      );
    }
    return resultado;
  }

  /// Gera o embedding de referência a partir da foto de perfil do aluno
  /// (campo `fotoBase64`, formato `data:image/...;base64,...`). Usado pra
  /// enrolamento inicial, antes de qualquer chamada por foto ter sido feita.
  /// Retorna `null` se a foto não existir ou nenhum rosto for detectado.
  static Future<List<double>?> embeddingFromBase64Photo(
    String base64Photo,
  ) async {
    await _getInterpreter();
    final virgula = base64Photo.indexOf(',');
    final dadosBase64 = virgula >= 0
        ? base64Photo.substring(virgula + 1)
        : base64Photo;
    Uint8List bytes;
    try {
      bytes = base64Decode(dadosBase64);
    } catch (_) {
      return null;
    }
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    decoded = img.bakeOrientation(decoded);

    // Foto de perfil normalmente já é um rosto só, de frente — detecta pra
    // recortar certinho em vez de usar a imagem inteira (que pode ter fundo).
    final tempPath =
        '${Directory.systemTemp.path}/_face_enroll_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final tempFile = File(tempPath);
    await tempFile.writeAsBytes(img.encodeJpg(decoded));
    try {
      final inputImage = InputImage.fromFilePath(tempPath);
      final faces = await _getDetector().processImage(inputImage);
      if (faces.isEmpty) {
        // Sem rosto detectado na foto de perfil — usa a imagem inteira como
        // fallback, melhor que não ter embedding nenhum.
        return _embedCrop(decoded, 0, 0, decoded.width.toDouble(), decoded.height.toDouble());
      }
      // Maior rosto detectado (mais provável de ser o foco da foto).
      final maior = faces.reduce(
        (a, b) =>
            (a.boundingBox.width * a.boundingBox.height) >
                (b.boundingBox.width * b.boundingBox.height)
            ? a
            : b,
      );
      final box = maior.boundingBox;
      return _embedCrop(decoded, box.left, box.top, box.width, box.height);
    } finally {
      if (await tempFile.exists()) await tempFile.delete();
    }
  }

  static List<double>? _embedCrop(
    img.Image source,
    double left,
    double top,
    double width,
    double height,
  ) {
    final x = left.clamp(0, source.width - 1).toInt();
    final y = top.clamp(0, source.height - 1).toInt();
    final w = width.clamp(1, source.width - x).toInt();
    final h = height.clamp(1, source.height - y).toInt();
    if (w <= 0 || h <= 0) return null;

    final crop = img.copyCrop(source, x: x, y: y, width: w, height: h);
    final resized = img.copyResize(
      crop,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Padronização por imagem: (x - média) / desvio, com piso no desvio
    // (igual ao pipeline original do FaceNet, ver FaceNetModel.kt).
    final n = _inputSize * _inputSize * 3;
    final raw = Float64List(n);
    var idx = 0;
    for (var yy = 0; yy < _inputSize; yy++) {
      for (var xx = 0; xx < _inputSize; xx++) {
        final pixel = resized.getPixel(xx, yy);
        raw[idx++] = pixel.r.toDouble();
        raw[idx++] = pixel.g.toDouble();
        raw[idx++] = pixel.b.toDouble();
      }
    }
    var soma = 0.0;
    for (final v in raw) {
      soma += v;
    }
    final media = soma / n;
    var somaSqDiff = 0.0;
    for (final v in raw) {
      final d = v - media;
      somaSqDiff += d * d;
    }
    final desvio = math.max(math.sqrt(somaSqDiff / n), 1.0 / math.sqrt(n));

    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (yy) => List.generate(
          _inputSize,
          (xx) => List.generate(3, (c) {
            final v = raw[(yy * _inputSize + xx) * 3 + c];
            return (v - media) / desvio;
          }),
        ),
      ),
    );

    return _runModelSync(input);
  }

  static List<double>? _runModelSync(List<dynamic> input) {
    // tflite_flutter é síncrono por chamada (`run`); o carregamento do
    // interpretador é assíncrono e feito antes, via [_getInterpreter].
    final interpreter = _interpreter;
    if (interpreter == null) return null;
    final output = List.generate(1, (_) => List.filled(128, 0.0));
    interpreter.run(input, output);
    return List<double>.from(output[0]);
  }

  /// Garante que o modelo já foi carregado — chamar antes de usar
  /// [detectFacesInFile] ou [embeddingFromBase64Photo] numa sessão nova
  /// (ex.: ao abrir a tela de chamada por foto).
  static Future<void> preload() => _getInterpreter();

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    var dot = 0.0, normA = 0.0, normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Compara um embedding contra uma lista de candidatos (alunoId ->
  /// embeddings de referência, pode ter mais de um por aluno) e retorna o
  /// alunoId mais parecido, ou `null` se nenhum passar do limiar de
  /// confiança mínima.
  static String? melhorCorrespondencia(
    List<double> embedding,
    Map<String, List<List<double>>> referenciasPorAluno,
  ) {
    String? melhorId;
    var melhorScore = _matchThreshold;
    referenciasPorAluno.forEach((alunoId, referencias) {
      for (final ref in referencias) {
        final score = cosineSimilarity(embedding, ref);
        if (score > melhorScore) {
          melhorScore = score;
          melhorId = alunoId;
        }
      }
    });
    return melhorId;
  }
}
