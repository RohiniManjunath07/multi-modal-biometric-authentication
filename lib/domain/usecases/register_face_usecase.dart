import 'dart:typed_data';
import '../entities/face_entity.dart';
import '../repositories/face_repository.dart';

/// Registers a new face embedding for the given username.
///
/// Throws a domain [Failure] subclass on any error.
class RegisterFaceUseCase {
  final FaceRepository _repository;
  const RegisterFaceUseCase(this._repository);

  /// [imageBytes]  – Raw image bytes captured from the camera.
  /// [username]    – Label to attach to the embedding.
  Future<FaceEntity> call({
    required Uint8List imageBytes,
    required String username,
  }) =>
      _repository.registerFace(
        imageBytes: imageBytes,
        username: username,
      );
}
