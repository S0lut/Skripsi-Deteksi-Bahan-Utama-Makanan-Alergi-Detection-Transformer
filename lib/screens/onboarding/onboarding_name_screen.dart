import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/allergy_provider.dart';
import '../../theme/app_theme.dart';
import 'onboarding_allergy_screen.dart';

class OnboardingNameScreen extends StatefulWidget {
  const OnboardingNameScreen({super.key});

  @override
  State<OnboardingNameScreen> createState() => _OnboardingNameScreenState();
}

class _OnboardingNameScreenState extends State<OnboardingNameScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _nameError = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _next() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = true);
      return;
    }
    context.read<AllergyProvider>().setUserName(name);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => const OnboardingAllergyScreen(),
        transitionsBuilder: (_, a, b, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      // ← TAMBAHKAN INI: supaya layout naik saat keyboard muncul
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            // ← GANTI Column biasa dengan SingleChildScrollView
            child: SingleChildScrollView(
              // Supaya konten tidak terpotong saat keyboard muncul
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                // Minimum height = tinggi layar, supaya tombol tetap di bawah
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),

                      // ── Logo ──────────────────────────────────
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.primary, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.18),
                              blurRadius: 20, spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('🍴',
                              style: TextStyle(fontSize: 42)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'NootriScan',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        'Analyze your meal with one click!',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // ── Step Indicator ─────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _dot(1, true),
                          const SizedBox(width: 6),
                          Container(
                              height: 2,
                              width: 32,
                              color: AppTheme.borderDark),
                          const SizedBox(width: 6),
                          _dot(2, false),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ── Title ──────────────────────────────────
                      const Text(
                        'Halo! Siapa nama Anda? 👋',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 10),

                      Text(
                        'Masukkan nama Anda agar NootriScan\nbisa menyapa Anda dengan personal.',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.5),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // ── Name Input ─────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600),
                          onChanged: (_) =>
                              setState(() => _nameError = false),
                          // ← Supaya keyboard tidak overlap input
                          onTapOutside: (_) =>
                              FocusScope.of(context).unfocus(),
                          decoration: InputDecoration(
                            hintText: 'Contoh: Budi Santoso',
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textHint,
                              fontWeight: FontWeight.w400,
                            ),
                            errorText: _nameError
                                ? 'Nama tidak boleh kosong'
                                : null,
                            prefixIcon: const Icon(
                                Icons.person_outline,
                                color: AppTheme.primary),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppTheme.borderDark,
                                  width: 1.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppTheme.borderDark,
                                  width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                  color: AppTheme.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 16),
                          ),
                        ),
                      ),

                      // ← GANTI Spacer() dengan Expanded yang flexible
                      const Expanded(child: SizedBox(height: 32)),

                      // ── Next Button ────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(16)),
                            elevation: 3,
                          ),
                          onPressed: _next,
                          child: const Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text('Lanjutkan',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(int n, bool active) {
    return Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: active ? AppTheme.primary : AppTheme.border,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$n',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppTheme.textHint,
          ),
        ),
      ),
    );
  }
}