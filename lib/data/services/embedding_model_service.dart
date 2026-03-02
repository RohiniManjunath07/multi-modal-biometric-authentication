import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';

/// Loads the MobileFaceNet TFLite model and runs face embedding inference.
///
/// Expected input:  [1, 112, 112, 3] float32 tensor (RGB, normalised to -1..1)
/// Expected output: [1, 192]          float32 tensor (raw embedding)
///
/// The output is L2-normalised before returning so that cosine similarity
/// can be computed as a simple dot product.
class EmbeddingModelService {
  Interpreter? _interpreter;
  bool _isInitialised = false;

  bool get isInitialised => _isInitialised;

  // ── Lifecycle ─────────────────────────────────────────────────────────

  /// Loads the TFLite model from [AppConstants.mobileFaceNetModelPath].
  /// Must be called once at app startup.
  Future<void> init() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        AppConstants.mobileFaceNetModelPath,
        options: options,
      );
      _isInitialised = true;
    } on PlatformException catch (e) {
      throw ModelFailure(
          'TFLite model could not be loaded: ${e.message}');
    } catch (e) {
      throw ModelFailure('TFLite model error: $e');
    }
  }

  /// Generates an L2-normalised embedding from a 112×112 RGB [Uint8List].
  ///
  /// [pixels] must be exactly 112 * 112 * 3 = 37 632 bytes in row-major
  /// RGB order.
  List<double> generateEmbedding(Uint8List pixels) {
    if (!_isInitialised || _interpreter == null) {
      throw const ModelFailure(
          'Embedding model is not initialised. Call init() first.');
    }

    // ── 1. Build input tensor: shape [1, 112, 112, 3] ─────────────────
    // Normalise each channel value from [0, 255] → [-1.0, 1.0]
    const int size = AppConstants.modelInputSize;
    final inputTensor = List.generate(
      1,
      (_) => List.generate(
        size,
        (row) => List.generate(
          size,
          (col) {
            final pixelOffset = (row * size + col) * 3;
            final r = (pixels[pixelOffset] / 127.5) - 1.0;
            final g = (pixels[pixelOffset + 1] / 127.5) - 1.0;
            final b = (pixels[pixelOffset + 2] / 127.5) - 1.0;
            return [r, g, b];
          },
        ),
      ),
    );

    // ── 2. Allocate output tensor: shape [1, 192] ──────────────────────
    final outputTensor = List.generate(
      1,
      (_) => List<double>.filled(AppConstants.embeddingSize, 0.0),
    );

    // ── 3. Run inference ───────────────────────────────────────────────
    try {
      _interpreter!.run(inputTensor, outputTensor);
    } catch (e) {
      throw ModelFailure('Inference failed: $e');
    }

    // ── 4. L2-normalise output ─────────────────────────────────────────
    final rawEmbedding = outputTensor[0];
    return _l2Normalise(rawEmbedding);
  }

  /// Computes cosine similarity between two L2-normalised embeddings.
  /// Since both are unit vectors, cosine similarity == dot product.
  static double cosineSimilarity(
      List<double> embeddingA, List<double> embeddingB) {
    if (embeddingA.length != embeddingB.length) {
      throw const ModelFailure(
          'Embedding dimension mismatch in similarity computation.');
    }
    double dot = 0.0;
    for (int i = 0; i < embeddingA.length; i++) {
      dot += embeddingA[i] * embeddingB[i];
    }
    // Clamp to [-1, 1] to guard against floating-point drift.
    return dot.clamp(-1.0, 1.0);
  }

  // ── Private helpers ───────────────────────────────────────────────────

  List<double> _l2Normalise(List<double> vector) {
    double norm = 0.0;
    for (final v in vector) {
      norm += v * v;
    }
    norm = math.sqrt(norm);
    if (norm == 0.0) return vector;
    return vector.map((v) => v / norm).toList();
  }

  /// Frees the interpreter resources.
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialised = false;
  }
}
