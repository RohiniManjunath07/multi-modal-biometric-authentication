import 'package:equatable/equatable.dart';

/// Base failure class. All domain-level errors extend this.
abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];

  @override
  String toString() => message;
}

/// Camera is not available or failed to initialise.
class CameraFailure extends Failure {
  const CameraFailure([super.message = 'Camera initialisation failed.']);
}

/// Camera or gallery permission was denied by the user.
class PermissionFailure extends Failure {
  const PermissionFailure(
      [super.message = 'Camera permission was denied. '
          'Please enable it in Settings.']);
}

/// ML Kit face detection returned an unexpected result.
class FaceDetectionFailure extends Failure {
  const FaceDetectionFailure([super.message = 'Face detection failed.']);
}

/// No face was found in the captured frame.
class NoFaceDetectedFailure extends Failure {
  const NoFaceDetectedFailure(
      [super.message = 'No face detected. Please look directly at the camera.']);
}

/// More than one face was found – only single-face images are accepted.
class MultipleFacesDetectedFailure extends Failure {
  const MultipleFacesDetectedFailure(
      [super.message =
          'Multiple faces detected. Please ensure only one face is visible.']);
}

/// The TFLite embedding model failed to load or run.
class ModelFailure extends Failure {
  const ModelFailure([super.message = 'Embedding model error.']);
}

/// Hive read/write operation failed.
class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Local storage operation failed.']);
}

/// The face being registered already exists in the DB.
class DuplicateFaceFailure extends Failure {
  const DuplicateFaceFailure(
      [super.message = 'A face is already registered with this username.']);
}

/// Generic / unhandled failure.
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
