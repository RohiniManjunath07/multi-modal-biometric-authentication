import 'package:equatable/equatable.dart';

/// Domain entity representing the outcome of a face authentication attempt.
class AuthResult extends Equatable {
  /// Whether a match was found above the similarity threshold.
  final bool isAuthenticated;

  /// Maximum cosine similarity score found (0.0 – 1.0).
  final double similarity;

  /// Username of the best-matching registered face (null if no match).
  final String? matchedUsername;

  const AuthResult({
    required this.isAuthenticated,
    required this.similarity,
    this.matchedUsername,
  });

  /// Convenience constructor for a failed authentication.
  const AuthResult.failed()
      : isAuthenticated = false,
        similarity = 0.0,
        matchedUsername = null;

  @override
  List<Object?> get props => [isAuthenticated, similarity, matchedUsername];
}
