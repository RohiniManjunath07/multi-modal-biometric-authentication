import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/face_provider.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/glass_card.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/result_card.dart';

/// Screen that handles the complete face registration flow:
///   1. Init camera
///   2. User types username
///   3. Capture + process → register
///   4. Show result
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FaceProvider>().initCamera();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    context.read<FaceProvider>().disposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FaceProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: _buildAppBar(context, provider),
          body: LoadingOverlay(
            isLoading: provider.isProcessing,
            message: _loadingMessage(provider.state),
            child: _buildBody(context, provider),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, FaceProvider provider) {
    return AppBar(
      title: const Text('Register Face'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (provider.state == FaceFlowState.success ||
            provider.state == FaceFlowState.error)
          TextButton(
            onPressed: () {
              _usernameController.clear();
              provider.reset();
            },
            child: const Text('Register Another'),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, FaceProvider provider) {
    // Show result card after success or error settlement.
    if (provider.state == FaceFlowState.success &&
        provider.lastRegisteredFace != null) {
      return _buildSuccessView(context, provider);
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
          // Camera preview
          CameraPreviewWidget(
            controller: provider.cameraController,
            isInitialized: provider.isCameraInitialized,
            overlayLabel: 'Position your face in the frame',
          ),
          const SizedBox(height: 24),
          // Username input
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Name',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('username_input'),
                    controller: _usernameController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Enter your name…',
                      prefixIcon: Icon(Icons.person_outline,
                          color: AppTheme.primary),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Name is required.';
                      }
                      if (val.trim().length < 2) {
                        return 'Name must be at least 2 characters.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    key: const Key('capture_register_btn'),
                    onPressed: provider.isCameraInitialized &&
                            !provider.isProcessing
                        ? _onRegister
                        : null,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Capture & Register'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Tips card
          _buildTipsCard(context),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, FaceProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResultCard(
            isSuccess: true,
            title: 'Face Registered!',
            subtitle:
                '"${provider.lastRegisteredFace!.username}" has been saved successfully.',
            icon: Icons.how_to_reg_outlined,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.home_outlined),
            label: const Text('Back to Home'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              _usernameController.clear();
              provider.reset();
            },
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Register Another'),
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
            title: 'Registration Failed',
            subtitle: provider.errorMessage ?? 'An unknown error occurred.',
            icon: Icons.error_outline,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.reset(),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppTheme.warningColor, size: 18),
              const SizedBox(width: 8),
              Text('Tips for best results',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            'Ensure good lighting on your face',
            'Keep only one face in the frame',
            'Look directly at the camera',
            'Remove glasses if possible',
          ].map((tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: AppTheme.accent)),
                    Expanded(
                        child: Text(tip,
                            style:
                                Theme.of(context).textTheme.bodyMedium)),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  void _onRegister() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context
        .read<FaceProvider>()
        .registerFace(_usernameController.text.trim());
  }

  String _loadingMessage(FaceFlowState state) {
    switch (state) {
      case FaceFlowState.requestingPermission:
        return 'Requesting camera permission…';
      case FaceFlowState.initializingCamera:
        return 'Initialising camera…';
      case FaceFlowState.capturing:
        return 'Capturing photo…';
      case FaceFlowState.processing:
        return 'Processing face…';
      default:
        return 'Please wait…';
    }
  }
}
