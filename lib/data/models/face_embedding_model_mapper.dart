import '../../domain/entities/face_entity.dart';
import 'face_embedding_model.dart';

/// Bidirectional mapper between [FaceEmbeddingModel] (data) and
/// [FaceEntity] (domain).
extension FaceEmbeddingModelMapper on FaceEmbeddingModel {
  FaceEntity toEntity() => FaceEntity(
        id: id,
        username: username,
        embedding: embedding,
        registeredAt:
            DateTime.fromMillisecondsSinceEpoch(registeredAtMs, isUtc: true),
      );
}

extension FaceEntityMapper on FaceEntity {
  FaceEmbeddingModel toModel() => FaceEmbeddingModel(
        id: id,
        username: username,
        embedding: embedding,
        registeredAtMs: registeredAt.millisecondsSinceEpoch,
      );
}
