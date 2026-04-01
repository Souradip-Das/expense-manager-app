import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'lock_screen.dart';
 
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
 
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
 
    return authState.when(
      // ── Still loading Firebase auth ──────────────────────────────────────
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A0A0A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6A0DAD)),
        ),
      ),
 
      // ── Firebase error ───────────────────────────────────────────────────
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Text('Auth error: $e',
              style: const TextStyle(color: Colors.redAccent)),
        ),
      ),
 
      // ── Auth resolved ────────────────────────────────────────────────────
      data: (user) {
        if (user == null) {
          return const LoginScreen();   // not signed in
        }
        return const LockScreen();     // signed in → biometric gate → home
      },
    );
  }
}