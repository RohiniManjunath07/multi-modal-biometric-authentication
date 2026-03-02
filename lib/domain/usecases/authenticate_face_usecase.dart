import 'dart:typed_data';
import '../entities/auth_result.dart';
import '../repositories/face_repository.dart';

/// Authenticates the face in [imageBytes] against all stored embeddings.
class AuthenticateFaceUseCase {
  final FaceRepository _repository;
  const AuthenticateFaceUseCase(this._repository);

  /// Returns an [AuthResult] with the match outcome.
  Future<AuthResult> call({required Uint8List imageBytes}) =>
      _repository.authenticateFace(imageBytes: imageBytes);
}
