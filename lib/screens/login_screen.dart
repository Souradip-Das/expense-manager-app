import 'package:flutter/material.dart';
import '../services/app_theme.dart';
import '../services/auth_service.dart';
import '../services/snackbar_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.signInWithGoogle();
      if (result == null && mounted) {
        SnackbarService.show(context, 'Sign-in cancelled.',
            type: SnackType.warning);
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.show(context, 'Sign-in failed. Please try again.',
            type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Stack(
        children: [
          // ── Background gradient blob ────────────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentBlue.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.5),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 38),
                  ),

                  const SizedBox(height: 28),

                  const Text('Budget Tracker',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  const Text(
                    'Track your spending.\nStay in control.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                        height: 1.5),
                  ),

                  const Spacer(flex: 2),

                  // Feature list
                  ...[
                    (Icons.pie_chart_outline,    'Monthly budget planning'),
                    (Icons.credit_card_outlined, 'Credit card tracking'),
                    (Icons.cloud_outlined,       'Sync across all devices'),
                    (Icons.lock_outline,         'Your data, completely private'),
                  ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.primary.withOpacity(0.3)),
                              ),
                              child: Icon(item.$1,
                                  color: AppTheme.primaryLight, size: 18),
                            ),
                            const SizedBox(width: 14),
                            Text(item.$2,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14)),
                          ],
                        ),
                      )),

                  const Spacer(),

                  // Google Sign-In button
                  GestureDetector(
                    onTap: _isLoading ? null : _signInWithGoogle,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppTheme.primary),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('G',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4285F4))),
                                  SizedBox(width: 12),
                                  Text('Continue with Google',
                                      style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    'Your data is stored securely in Firebase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
