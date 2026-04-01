import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/snackbar_service.dart';
import 'lock_screen.dart';
 
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
      // On success, authStateProvider fires and AuthGate navigates automatically
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
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),
 
              // ── Logo / Icon ─────────────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A0DAD).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF6A0DAD), width: 1.5),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Color(0xFF6A0DAD), size: 44),
              ),
 
              const SizedBox(height: 24),
 
              // ── Title ───────────────────────────────────────────────────
              const Text(
                'Budget Tracker',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Track your spending.\nStay in control.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white54,
                    fontSize: 15,
                    height: 1.5),
              ),
 
              const Spacer(flex: 2),
 
              // ── Features list ───────────────────────────────────────────
              ...[
                ('📊', 'Monthly budget planning'),
                ('💳', 'Credit card tracking'),
                ('☁️', 'Sync across all your devices'),
                ('🔒', 'Your data, completely private'),
              ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Text(item.$1, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Text(item.$2,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  )),
 
              const Spacer(flex: 1),
 
              // ── Google Sign-In Button ───────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    disabledBackgroundColor: Colors.white24,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF6A0DAD)),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google G logo
                            Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                  shape: BoxShape.circle),
                              child: const Text(
                                'G',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4285F4)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87),
                            ),
                          ],
                        ),
                ),
              ),
 
              const SizedBox(height: 16),
              const Text(
                'By continuing, you agree to our Terms of Service.\nYour data is stored securely in Firebase.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white30, fontSize: 11),
              ),
 
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}