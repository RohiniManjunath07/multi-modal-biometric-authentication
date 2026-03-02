import '../repositories/face_repository.dart';

/// Deletes a registered face by its [id].
class DeleteFaceUseCase {
  final FaceRepository _repository;
  const DeleteFaceUseCase(this._repository);

  Future<void> call(String id) => _repository.deleteFace(id);
}
