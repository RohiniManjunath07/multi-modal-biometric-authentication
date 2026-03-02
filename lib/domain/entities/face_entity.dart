import 'package:equatable/equatable.dart';

/// Domain entity representing a registered face.
class FaceEntity extends Equatable {
  /// Unique id (UUID v4).
  final String id;

  /// Display name given by the user at registration.
  final String username;

  /// 192-dimensional MobileFaceNet embedding (L2-normalised).
  final List<double> embedding;

  /// UTC timestamp of registration.
  final DateTime registeredAt;

  const FaceEntity({
    required this.id,
    required this.username,
    required this.embedding,
    required this.registeredAt,
  });

  @override
  List<Object?> get props => [id, username, registeredAt];
}
