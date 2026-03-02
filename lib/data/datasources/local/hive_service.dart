import 'package:hive/hive.dart';

import '../../../core/errors/failures.dart';
import '../../models/face_embedding_model.dart';

/// Abstraction layer for all Hive operations.
/// Keeps Hive-specific code in one place; other classes depend on this.
class HiveService {
  static const String faceEmbeddingsBoxName = 'face_embeddings';

  Box<FaceEmbeddingModel> get _box =>
      Hive.box<FaceEmbeddingModel>(faceEmbeddingsBoxName);

  // ── CRUD ─────────────────────────────────────────────────────────────

  /// Persists [model] using its [id] as the Hive key.
  Future<void> saveFaceEmbedding(FaceEmbeddingModel model) async {
    try {
      await _box.put(model.id, model);
    } catch (e) {
      throw const StorageFailure('Failed to save face embedding.');
    }
  }

  /// Returns all stored [FaceEmbeddingModel] entries.
  List<FaceEmbeddingModel> getAllFaceEmbeddings() {
    try {
      return _box.values.toList();
    } catch (e) {
      throw const StorageFailure('Failed to read face embeddings.');
    }
  }

  /// Deletes the entry keyed by [id]. No-op if not found.
  Future<void> deleteFaceEmbedding(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw const StorageFailure('Failed to delete face embedding.');
    }
  }

  /// Removes every stored face embedding.
  Future<void> clearAll() async {
    try {
      await _box.clear();
    } catch (e) {
      throw const StorageFailure('Failed to clear face embeddings.');
    }
  }

  /// Returns true if any face with [username] already exists.
  bool usernameExists(String username) {
    return _box.values
        .any((m) => m.username.toLowerCase() == username.toLowerCase());
  }
}
