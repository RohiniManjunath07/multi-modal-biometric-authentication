import 'dart:async';
import 'dart:typed_data';
import 'package:local_auth/local_auth.dart';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/face_entity.dart';
import '../../domain/usecases/authenticate_face_usecase.dart';
import '../../domain/usecases/delete_face_usecase.dart';
import '../../domain/usecases/get_all_faces_usecase.dart';
import '../../domain/usecases/register_face_usecase.dart';

/// Distinct UI states the camera/processing flow can be in.
enum FaceFlowState {
  idle,
  requestingPermission,
  initializingCamera,
  cameraReady,
  capturing,
  processing,
  success,
  error,
}

/// Central ChangeNotifier consumed by all face-related screens.
///
/// Responsibilities:
///   * Camera lifecycle (init, dispose, stream).
///   * Triggering registration and authentication use-cases.
///   * Exposing reactive state to the UI.
class FaceProvider extends ChangeNotifier {
  // ── Use-cases ─────────────────────────────────────────────────────────
  final RegisterFaceUseCase _registerFaceUseCase;
  final AuthenticateFaceUseCase _authenticateFaceUseCase;
  final GetAllFacesUseCase _getAllFacesUseCase;
  final DeleteFaceUseCase _deleteFaceUseCase;
  final LocalAuthentication _localAuth = LocalAuthentication();

  FaceProvider({
    required RegisterFaceUseCase registerFaceUseCase,
    required AuthenticateFaceUseCase authenticateFaceUseCase,
    required GetAllFacesUseCase getAllFacesUseCase,
    required DeleteFaceUseCase deleteFaceUseCase,
  })  : _registerFaceUseCase = registerFaceUseCase,
        _authenticateFaceUseCase = authenticateFaceUseCase,
        _getAllFacesUseCase = getAllFacesUseCase,
        _deleteFaceUseCase = deleteFaceUseCase;

  // ── State ─────────────────────────────────────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  FaceFlowState _state = FaceFlowState.idle;
  String? _errorMessage;
  AuthResult? _lastAuthResult;
  FaceEntity? _lastRegisteredFace;
  List<FaceEntity> _registeredFaces = [];

  // ── Getters ───────────────────────────────────────────────────────────
  CameraController? get cameraController => _cameraController;
  bool get isCameraInitialized =>
      _cameraController?.value.isInitialized ?? false;
  FaceFlowState get state => _state;
  String? get errorMessage => _errorMessage;
  AuthResult? get lastAuthResult => _lastAuthResult;
  FaceEntity? get lastRegisteredFace => _lastRegisteredFace;
  List<FaceEntity> get registeredFaces => List.unmodifiable(_registeredFaces);
  bool get isProcessing =>
      _state == FaceFlowState.capturing ||
      _state == FaceFlowState.processing ||
      _state == FaceFlowState.initializingCamera;

  // ── Camera ────────────────────────────────────────────────────────────

  /// Requests camera permission and initialises the front camera.
  Future<void> initCamera() async {
    _setState(FaceFlowState.requestingPermission);

    final status = await Permission.camera.request();
    if (!status.isGranted) {
      _setError(
          const PermissionFailure().message, FaceFlowState.error);
      return;
    }

    _setState(FaceFlowState.initializingCamera);
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        _setError('No cameras found on this device.', FaceFlowState.error);
        return;
      }

      // Prefer front camera for face recognition.
      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      await _disposeCameraController();

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      _setState(FaceFlowState.cameraReady);
    } on CameraException catch (e) {
      _setError('Camera error: ${e.description}', FaceFlowState.error);
    } catch (e) {
      _setError('Failed to initialise camera: $e', FaceFlowState.error);
    }
  }

  /// Safely disposes the active [CameraController].
  Future<void> disposeCamera() async {
    await _disposeCameraController();
    _setState(FaceFlowState.idle);
  }

  // ── Registration ──────────────────────────────────────────────────────

  /// Captures a photo with the current camera and registers it under [username].
  Future<void> registerFace(String username) async {
    if (!isCameraInitialized) return;

    _setState(FaceFlowState.capturing);
    _lastRegisteredFace = null;
    _errorMessage = null;

    try {
      final xFile = await _cameraController!.takePicture();
      final imageBytes = await xFile.readAsBytes();

      _setState(FaceFlowState.processing);

      final entity = await _registerFaceUseCase(
        imageBytes: imageBytes,
        username: username.trim(),
      );

      _lastRegisteredFace = entity;
      await loadAllFaces();
      _setState(FaceFlowState.success);
    } on Failure catch (f) {
      _setError(f.message, FaceFlowState.error);
    } catch (e) {
      _setError('Unexpected error: $e', FaceFlowState.error);
    }
  }

  // ── Authentication ────────────────────────────────────────────────────

  /// Captures a photo and authenticates it against stored faces.
  Future<void> authenticateFace() async {
    if (!isCameraInitialized) return;

    _setState(FaceFlowState.capturing);
    _lastAuthResult = null;
    _errorMessage = null;

    try {
      final xFile = await _cameraController!.takePicture();
      final imageBytes = await xFile.readAsBytes();

      _setState(FaceFlowState.processing);

      final result =
          await _authenticateFaceUseCase(imageBytes: imageBytes);
      _lastAuthResult = result;
      _setState(FaceFlowState.success);
    } on Failure catch (f) {
      _setError(f.message, FaceFlowState.error);
    } catch (e) {
      _setError('Unexpected error: $e', FaceFlowState.error);
    }
  }

  // ── Biometric Authentication ──────────────────────────────────────────

Future<bool> authenticateWithBiometrics() async {
  try {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();

    if (!canCheck || !isSupported) {
      _setError(
        "Biometric authentication not available on this device.",
        FaceFlowState.error,
      );
      return false;
    }

    final didAuthenticate = await _localAuth.authenticate(
      localizedReason: 'Authenticate to continue',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );

    if (didAuthenticate) {
      _setState(FaceFlowState.success);
    }

    return didAuthenticate;
  } catch (e) {
    _setError("Biometric error: $e", FaceFlowState.error);
    return false;
  }
}

  // ── Faces list ────────────────────────────────────────────────────────

  /// Loads all registered faces from the repository.
  Future<void> loadAllFaces() async {
    try {
      _registeredFaces = await _getAllFacesUseCase();
      notifyListeners();
    } catch (_) {
      // Non-critical – swallow silently.
    }
  }

  /// Deletes the face with [id] and refreshes the list.
  Future<void> deleteFace(String id) async {
    try {
      await _deleteFaceUseCase(id);
      await loadAllFaces();
    } on Failure catch (f) {
      _setError(f.message, FaceFlowState.error);
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────

  /// Resets transient state (error, results) but keeps the camera alive.
  void reset() {
    _errorMessage = null;
    _lastAuthResult = null;
    _lastRegisteredFace = null;
    _setState(isCameraInitialized
        ? FaceFlowState.cameraReady
        : FaceFlowState.idle);
  }

  // ── Private helpers ───────────────────────────────────────────────────

  void _setState(FaceFlowState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message, FaceFlowState state) {
    _errorMessage = message;
    _state = state;
    notifyListeners();
  }

  Future<void> _disposeCameraController() async {
    if (_cameraController != null) {
      if (_cameraController!.value.isInitialized) {
        await _cameraController!.dispose();
      }
      _cameraController = null;
    }
  }

  @override
  void dispose() {
    _disposeCameraController();
    super.dispose();
  }
}
