import 'package:hive/hive.dart';

part 'face_embedding_model.g.dart';

/// Hive data model that persists a face embedding for one registered user.
/// Type id 0 is reserved for this adapter.
@HiveType(typeId: 0)
class FaceEmbeddingModel extends HiveObject {
  /// Unique identifier (UUID v4).
  @HiveField(0)
  final String id;

  /// Display name provided by the user at registration.
  @HiveField(1)
  final String username;

  /// 192-dimensional MobileFaceNet L2-normalised embedding.
  @HiveField(2)
  final List<double> embedding;

  /// UTC epoch milliseconds of the registration moment.
  @HiveField(3)
  final int registeredAtMs;

  FaceEmbeddingModel({
    required this.id,
    required this.username,
    required this.embedding,
    required this.registeredAtMs,
  });
}
