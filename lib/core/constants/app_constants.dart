/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // ── Model ──────────────────────────────────────────────────────────
  /// Path to MobileFaceNet TFLite model asset.
  static const String mobileFaceNetModelPath =
      'assets/models/mobilefacenet.tflite';

  /// Dimensions the model expects (112 × 112 RGB).
  static const int modelInputSize = 112;

  /// Length of the embedding vector produced by MobileFaceNet.
  static const int embeddingSize = 192;

  // ── Recognition ───────────────────────────────────────────────────
  /// Cosine-similarity threshold above which two faces are considered
  /// the same person.
  static const double similarityThreshold = 0.70;

  // ── Face detection ────────────────────────────────────────────────
  /// Minimum face size (pixels) considered valid for embedding extraction.
  static const double minFaceSize = 80.0;

  // ── UI ────────────────────────────────────────────────────────────
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration cameraInitTimeout = Duration(seconds: 10);
}
