import 'package:get_it/get_it.dart';

import '../../data/datasources/local/hive_service.dart';
import '../../data/repositories/face_repository_impl.dart';
import '../../data/services/embedding_model_service.dart';
import '../../data/services/face_service.dart';
import '../../domain/repositories/face_repository.dart';
import '../../domain/usecases/authenticate_face_usecase.dart';
import '../../domain/usecases/delete_face_usecase.dart';
import '../../domain/usecases/get_all_faces_usecase.dart';
import '../../domain/usecases/register_face_usecase.dart';
import '../../presentation/providers/face_provider.dart';

/// Simple GetIt-based service locator for dependency injection.
/// Call [ServiceLocator.init] once at app startup before accessing any
/// registered type.
class ServiceLocator {
  ServiceLocator._();

  static final GetIt _locator = GetIt.instance;

  /// Returns a registered instance of type [T].
  static T get<T extends Object>() => _locator<T>();

  /// Registers all services, repositories, use-cases, and providers.
  static Future<void> init() async {
    // ── Data Sources ─────────────────────────────────────────────────
    _locator.registerLazySingleton<HiveService>(() => HiveService());

    // ── Services ─────────────────────────────────────────────────────
    final embeddingModelService = EmbeddingModelService();
    await embeddingModelService.init();
    _locator.registerSingleton<EmbeddingModelService>(embeddingModelService);

    _locator.registerLazySingleton<FaceService>(
      () => FaceService(_locator<EmbeddingModelService>()),
    );

    // ── Repositories ──────────────────────────────────────────────────
    _locator.registerLazySingleton<FaceRepository>(
      () => FaceRepositoryImpl(
        hiveService: _locator<HiveService>(),
        faceService: _locator<FaceService>(),
      ),
    );

    // ── Use Cases ─────────────────────────────────────────────────────
    _locator.registerLazySingleton<RegisterFaceUseCase>(
      () => RegisterFaceUseCase(_locator<FaceRepository>()),
    );
    _locator.registerLazySingleton<AuthenticateFaceUseCase>(
      () => AuthenticateFaceUseCase(_locator<FaceRepository>()),
    );
    _locator.registerLazySingleton<GetAllFacesUseCase>(
      () => GetAllFacesUseCase(_locator<FaceRepository>()),
    );
    _locator.registerLazySingleton<DeleteFaceUseCase>(
      () => DeleteFaceUseCase(_locator<FaceRepository>()),
    );

    // ── Presentation ──────────────────────────────────────────────────
    _locator.registerFactory<FaceProvider>(
      () => FaceProvider(
        registerFaceUseCase: _locator<RegisterFaceUseCase>(),
        authenticateFaceUseCase: _locator<AuthenticateFaceUseCase>(),
        getAllFacesUseCase: _locator<GetAllFacesUseCase>(),
        deleteFaceUseCase: _locator<DeleteFaceUseCase>(),
      ),
    );
  }
}
