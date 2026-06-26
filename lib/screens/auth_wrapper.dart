import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/allergy_provider.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'main_shell.dart';
import 'onboarding/onboarding_name_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Masih loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }

        final user = snapshot.data;

        // Belum login → LoginScreen
        if (user == null) {
          return const LoginScreen();
        }

        // Sudah login → cek profil
        // Navigasi manual di email/google sudah handle ini
        // AuthWrapper hanya sebagai fallback saat app dibuka ulang
        return Consumer<AllergyProvider>(
          builder: (context, allergyProv, _) {
            if (!allergyProv.isLoaded) {
              return const _SplashScreen();
            }
            if (!allergyProv.isProfileComplete) {
              return const OnboardingNameScreen();
            }
            return const MainShell();
          },
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B8E72),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🍴', style: TextStyle(fontSize: 50)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('NootriScan',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Analyze your meal with one click!',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8))),
            const SizedBox(height: 48),
            const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}