import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/face_provider.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/result_card.dart';

/// Screen for real-time face authentication.
///
/// Flow:
///   1. Camera initialises automatically.
///   2. User presses "Authenticate".
///   3. A photo is captured and processed.
///   4. Result card shows matched username or "Face not recognized".
class AuthenticateScreen extends StatefulWidget {
  const AuthenticateScreen({super.key});

  @override
  State<AuthenticateScreen> createState() => _AuthenticateScreenState();
}

class _AuthenticateScreenState extends State<AuthenticateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FaceProvider>().initCamera();
    });
  }

  @override
  void dispose() {
    context.read<FaceProvider>().disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FaceProvider>(
      builder: (context, provider, _) => Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          title: const Text('Authenticate'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (provider.state == FaceFlowState.success ||
                provider.state == FaceFlowState.error)
              TextButton(
                onPressed: provider.reset,
                child: const Text('Retry'),
              ),
          ],
        ),
        body: LoadingOverlay(
          isLoading: provider.isProcessing,
          message: _loadingMessage(provider.state),
          child: _buildBody(context, provider),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, FaceProvider provider) {
    if (provider.state == FaceFlowState.success &&
        provider.lastAuthResult != null) {
      return _buildResultView(context, provider);
    }
    if (provider.state == FaceFlowState.error) {
      return _buildErrorView(context, provider);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CameraPreviewWidget(
            controller: provider.cameraController,
            isInitialized: provider.isCameraInitialized,
            overlayLabel: 'Look directly at the camera',
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Ready to authenticate',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Press the button below and hold still while '
                  'we scan your face.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  key: const Key('authenticate_btn'),
                  onPressed: provider.isCameraInitialized &&
                          !provider.isProcessing
                      ? () => provider.authenticateFace()
                      : null,
                  icon: const Icon(Icons.face_unlock_outlined),
                  label: const Text('Authenticate Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildRegisteredFacesInfo(context, provider),
        ],
      ),
    );
  }

  Widget _buildResultView(BuildContext context, FaceProvider provider) {
    final result = provider.lastAuthResult!;
    final pct = (result.similarity * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResultCard(
            isSuccess: result.isAuthenticated,
            title: result.isAuthenticated
                ? 'Welcome, ${result.matchedUsername}!'
                : 'Face Not Recognized',
            subtitle: result.isAuthenticated
                ? 'Authenticated with $pct% confidence.'
                : 'No matching face found in the database.\n'
                    'Best match: $pct% (below threshold).',
            icon: result.isAuthenticated
                ? Icons.verified_outlined
                : Icons.no_accounts_outlined,
          ),
          const SizedBox(height: 24),
          // Similarity meter
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confidence',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: result.similarity.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: AppTheme.backgroundSurface,
                    valueColor: AlwaysStoppedAnimation(
                      result.isAuthenticated
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$pct%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: result.isAuthenticated
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                          fontWeight: FontWeight.w600,
                        )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: provider.reset,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  result.isAuthenticated ? AppTheme.accent : AppTheme.primary,
              minimumSize: const Size.fromHeight(54),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, FaceProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResultCard(
            isSuccess: false,
            title: 'Authentication Error',
            subtitle: provider.errorMessage ?? 'An unknown error occurred.',
            icon: Icons.error_outline_rounded,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: provider.reset,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredFacesInfo(
      BuildContext context, FaceProvider provider) {
    final count = provider.registeredFaces.length;
    if (count == 0) {
      return GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.info_outline,
                color: AppTheme.warningColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No faces registered yet. Go to Register Face first.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.people_outline,
              color: AppTheme.accent, size: 18),
          const SizedBox(width: 10),
          Text(
            '$count face${count == 1 ? '' : 's'} in database',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _loadingMessage(FaceFlowState state) {
    switch (state) {
      case FaceFlowState.requestingPermission:
        return 'Requesting camera permission…';
      case FaceFlowState.initializingCamera:
        return 'Starting camera…';
      case FaceFlowState.capturing:
        return 'Capturing…';
      case FaceFlowState.processing:
        return 'Analysing face…';
      default:
        return 'Please wait…';
    }
  }
}
