import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../core/theme/app_theme.dart';

/// Displays a camera preview with a face-outline overlay and status label.
/// Falls back to a loading shimmer while the camera initialises.
class CameraPreviewWidget extends StatelessWidget {
  final CameraController? controller;
  final bool isInitialized;
  final String overlayLabel;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.isInitialized,
    this.overlayLabel = 'Position your face in the frame',
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera feed or placeholder
            isInitialized && controller != null
                ? CameraPreview(controller!)
                : _buildPlaceholder(),
            // Gradient overlay at bottom
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Face guide oval
            Center(
              child: CustomPaint(
                size: const Size(200, 260),
                painter: _FaceOvalPainter(),
              ),
            ),
            // Label at bottom
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Text(
                overlayLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.backgroundCard,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitPulse(color: AppTheme.primary, size: 50),
            SizedBox(height: 16),
            Text(
              'Starting camera…',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws a semi-transparent oval guide to help users centre their face.
class _FaceOvalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width,
        height: size.height);

    // Darken outside the oval
    final outerPath = Path()
      ..addRect(
          Rect.fromLTWH(-1000, -1000, size.width + 2000, size.height + 2000))
      ..addOval(rect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
        outerPath, Paint()..color = Colors.black.withOpacity(0.35));

    // Oval border
    canvas.drawOval(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppTheme.primary
        ..strokeWidth = 2.5,
    );

    // Corner arcs highlight
    const arcLen = 40.0;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppTheme.accent
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Top-left
    path.moveTo(rect.left, rect.top + arcLen);
    path.arcToPoint(Offset(rect.left + arcLen, rect.top),
        radius: const Radius.circular(40));
    // Top-right
    path.moveTo(rect.right - arcLen, rect.top);
    path.arcToPoint(Offset(rect.right, rect.top + arcLen),
        radius: const Radius.circular(40));
    // Bottom-right
    path.moveTo(rect.right, rect.bottom - arcLen);
    path.arcToPoint(Offset(rect.right - arcLen, rect.bottom),
        radius: const Radius.circular(40));
    // Bottom-left
    path.moveTo(rect.left + arcLen, rect.bottom);
    path.arcToPoint(Offset(rect.left, rect.bottom - arcLen),
        radius: const Radius.circular(40));

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
