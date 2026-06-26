import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../providers/allergy_provider.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';

class OnboardingAllergyScreen extends StatefulWidget {
  const OnboardingAllergyScreen({super.key});

  @override
  State<OnboardingAllergyScreen> createState() =>
      _OnboardingAllergyScreenState();
}

class _OnboardingAllergyScreenState extends State<OnboardingAllergyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prov = context.read<AllergyProvider>();
    await prov.saveProfile();
    if (!mounted) return;
    // AuthWrapper will handle navigation via StreamBuilder
    // Just push MainShell on top, AuthWrapper will take over next time
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _dot(1, false),
                        const SizedBox(width: 6),
                        Container(
                            height: 2, width: 32, color: AppTheme.primary),
                        const SizedBox(width: 6),
                        _dot(2, true),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Consumer<AllergyProvider>(
                      builder: (_, p, __) => Text(
                        'Halo, ${p.userName}! 👋',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pilih bahan makanan yang memicu\nalergi Anda:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── Grid ───────────────────────────────────────────
              Expanded(
                child: Consumer<AllergyProvider>(
                  builder: (context, provider, _) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Column(
                        children: [
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: provider.allergyItems.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.88,
                            ),
                            itemBuilder: (context, index) {
                              final item = provider.allergyItems[index];
                              return _AllergyCard(
                                name: item.name,
                                iconAsset: item.iconAsset,
                                isSelected: item.isSelected,
                                onTap: () =>
                                    provider.toggleAllergy(item.id),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => provider.clearAllAllergies(),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: AppTheme.primary, width: 1.5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Tidak Memiliki Alergi',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Save Button ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                decoration: const BoxDecoration(
                  color: AppTheme.bgPrimary,
                  border:
                      Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                    ),
                    onPressed: _finish,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Simpan & Mulai',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(int n, bool active) {
    return Container(
      width: 28,
      height: 28,
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

class _AllergyCard extends StatelessWidget {
  final String name;
  final String iconAsset;
  final bool isSelected;
  final VoidCallback onTap;

  const _AllergyCard({
    required this.name,
    required this.iconAsset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.white,
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : const Color(0xFFDDEEE6),
            width: isSelected ? 2.2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primary.withOpacity(0.14)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      color: Colors.white, size: 13),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: SvgPicture.asset(iconAsset,
                      width: 58, height: 58),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppTheme.primaryDark
                        : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
