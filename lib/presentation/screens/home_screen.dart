import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../providers/face_provider.dart';
import '../widgets/animated_gradient_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/stats_badge.dart';
import 'authenticate_screen.dart';
import 'manage_faces_screen.dart';
import 'register_screen.dart';
import 'register_voice_screen.dart';

/// Main landing screen with Register and Authenticate actions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
        parent: _animController, curve: Curves.easeOutCubic);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController.forward();

    // Load registered faces count on startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FaceProvider>().loadAllFaces();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────────────
                SliverToBoxAdapter(child: _buildHeader(context)),
                // ── Hero card ────────────────────────────────────────
                SliverToBoxAdapter(child: _buildHeroCard(context)),
                // ── Action buttons ───────────────────────────────────
                SliverToBoxAdapter(child: _buildActionButtons(context)),
                // ── Bottom spacer ─────────────────────────────────────
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recognition System',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [
                              AppTheme.primary,
                              AppTheme.accent,
                            ],
                          ).createShader(
                              const Rect.fromLTWH(0, 0, 150, 40)),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Real-time face, voice recognition and biometric authentication',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          // Manage faces button
          Consumer<FaceProvider>(
            builder: (_, provider, __) => GestureDetector(
              onTap: () => _navigateTo(context, const ManageFacesScreen()),
              child: StatsBadge(count: provider.registeredFaces.length),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: GlassCard(
        child: Column(
          children: [
            // Animated face icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [
                    Color(0xFF3A31CC),
                    AppTheme.backgroundCard,
                  ],
                ),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.face_retouching_natural,
                size: 60,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Secure Face Recognition',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Register your face once, then authenticate instantly '
              'using MobileFaceNet AI embedded on-device.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Feature pills
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: const [
                _FeaturePill(icon: Icons.lock_outline, label: 'On-device ML'),
                _FeaturePill(
                    icon: Icons.privacy_tip_outlined, label: 'Private'),
                _FeaturePill(
                    icon: Icons.offline_bolt_outlined, label: 'Offline'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          // Register button
          AnimatedGradientButton(
            id: 'register_face_btn',
            label: 'Register Face',
            icon: Icons.person_add_alt_1_outlined,
            gradientColors: const [Color(0xFF6C63FF), Color(0xFF4B44CC)],
            onPressed: () => _navigateTo(context, const RegisterScreen()),
          ),
          const SizedBox(height: 16),

          // 🟣 Register Voice  (PASTE HERE)
          AnimatedGradientButton(
            id: 'register_voice_btn',
            label: 'Register Voice',
            icon: Icons.mic,
            gradientColors: const [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            onPressed: () =>
                _navigateTo(context, const RegisterVoiceScreen()),
          ),

          const SizedBox(height: 16),

          // Authenticate button
          AnimatedGradientButton(
            id: 'authenticate_face_btn',
            label: 'Authenticate Face',
            icon: Icons.verified_user_outlined,
            gradientColors: const [Color(0xFF00D4AA), Color(0xFF00916E)],
            onPressed: () =>
                _navigateTo(context, const AuthenticateScreen()),
          ),

          //from here
          const SizedBox(height: 16),

            AnimatedGradientButton(
              id: 'biometric_auth_btn',
              label: 'Authenticate with Biometrics',
              icon: Icons.fingerprint,
              gradientColors: const [Color(0xFFFF8C42), Color(0xFFFF5E00)],
                onPressed: () async {
                final provider = context.read<FaceProvider>();
                final success = await provider.authenticateWithBiometrics();

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                        ? "Biometric Authentication Successful"
                        : "Authentication Failed",
                      ),
                    ),
                  );
                },
          ),
          const SizedBox(height: 16),
          // Manage faces
          OutlinedButton.icon(
            onPressed: () =>
                _navigateTo(context, const ManageFacesScreen()),
            icon: const Icon(Icons.manage_accounts_outlined),
            label: const Text('Manage Registered Faces'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));
  }
}

/// Small pill widget for feature callouts.
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.accent),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
