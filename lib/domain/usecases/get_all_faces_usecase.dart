import '../entities/face_entity.dart';
import '../repositories/face_repository.dart';

/// Returns the list of all registered [FaceEntity] objects.
class GetAllFacesUseCase {
  final FaceRepository _repository;
  const GetAllFacesUseCase(this._repository);

  Future<List<FaceEntity>> call() => _repository.getAllFaces();
}
