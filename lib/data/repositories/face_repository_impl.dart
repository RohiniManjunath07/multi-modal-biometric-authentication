import 'dart:typed_data';

import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/face_entity.dart';
import '../../domain/repositories/face_repository.dart';
import '../datasources/local/hive_service.dart';
import '../models/face_embedding_model.dart';
import '../models/face_embedding_model_mapper.dart';
import '../services/embedding_model_service.dart';
import '../services/face_service.dart';

/// Concrete implementation of [FaceRepository].
///
/// Wires [FaceService] (detection + embedding extraction) with
/// [HiveService] (persistence) and [EmbeddingModelService] (similarity).
class FaceRepositoryImpl implements FaceRepository {
  final HiveService _hiveService;
  final FaceService _faceService;

  static const _uuid = Uuid();

  FaceRepositoryImpl({
    required HiveService hiveService,
    required FaceService faceService,
  })  : _hiveService = hiveService,
        _faceService = faceService;

  // ── FaceRepository implementation ─────────────────────────────────────

  @override
  Future<FaceEntity> registerFace({
    required Uint8List imageBytes,
    required String username,
  }) async {
    // Guard: username must not already exist.
    if (_hiveService.usernameExists(username)) {
      throw DuplicateFaceFailure(
          'A face for "$username" is already registered.');
    }

    // Extract embedding from the still image.
    final embedding =
        await _faceService.getEmbeddingFromImageBytes(imageBytes);

    // Build and persist the model.
    final model = FaceEmbeddingModel(
      id: _uuid.v4(),
      username: username,
      embedding: embedding,
      registeredAtMs: DateTime.now().toUtc().millisecondsSinceEpoch,
    );
    await _hiveService.saveFaceEmbedding(model);
    return model.toEntity();
  }

  @override
  Future<AuthResult> authenticateFace({required Uint8List imageBytes}) async {
    // Extract live embedding.
    final liveEmbedding =
        await _faceService.getEmbeddingFromImageBytes(imageBytes);

    final stored = _hiveService.getAllFaceEmbeddings();
    if (stored.isEmpty) {
      return const AuthResult.failed();
    }

    // Find the stored face with the highest cosine similarity.
    double bestSimilarity = -1.0;
    String? bestUsername;

    for (final model in stored) {
      final sim = EmbeddingModelService.cosineSimilarity(
          liveEmbedding, model.embedding);
      if (sim > bestSimilarity) {
        bestSimilarity = sim;
        bestUsername = model.username;
      }
    }

    final isAuthenticated =
        bestSimilarity >= AppConstants.similarityThreshold;

    return AuthResult(
      isAuthenticated: isAuthenticated,
      similarity: bestSimilarity,
      matchedUsername: isAuthenticated ? bestUsername : null,
    );
  }

  @override
  Future<List<FaceEntity>> getAllFaces() async {
    return _hiveService
        .getAllFaceEmbeddings()
        .map((m) => (m as FaceEmbeddingModel).toEntity())
        .toList();
  }

  @override
  Future<void> deleteFace(String id) => _hiveService.deleteFaceEmbedding(id);

  @override
  Future<void> clearAllFaces() => _hiveService.clearAll();
}
