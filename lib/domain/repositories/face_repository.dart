import 'dart:typed_data';
import '../entities/auth_result.dart';
import '../entities/face_entity.dart';

/// Abstract contract for all face-related data operations.
/// The data layer must implement this interface.
abstract class FaceRepository {
  /// Registers a new face from the given [imageBytes] (JPEG/PNG) with
  /// a [username] label. Returns the persisted [FaceEntity] on success.
  Future<FaceEntity> registerFace({
    required Uint8List imageBytes,
    required String username,
  });

  /// Authenticates against stored faces using [imageBytes].
  /// Returns an [AuthResult] describing the outcome.
  Future<AuthResult> authenticateFace({required Uint8List imageBytes});

  /// Returns every registered [FaceEntity] from local storage.
  Future<List<FaceEntity>> getAllFaces();

  /// Deletes the face with the given [id].
  Future<void> deleteFace(String id);

  /// Removes all registered faces from storage.
  Future<void> clearAllFaces();
}
