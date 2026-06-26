import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/allergy_provider.dart';
import '../theme/app_theme.dart';
import 'allergy_profile_screen.dart';
import 'processing_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickImage(
    BuildContext context,
    ImageSource source,
  ) async {
    final picker = ImagePicker();

    try {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProcessingScreen(
              imageFile: File(pickedFile.path),
            ),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gambar tidak dapat dibuka. Silakan coba kembali.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _firstName(String fullName) {
    final value = fullName.trim();

    if (value.isEmpty) {
      return 'Pengguna';
    }

    return value.split(RegExp(r'\s+')).first;
  }

  void _openAllergyProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AllergyProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 760;

            return Stack(
              children: [
                const Positioned(
                  top: -90,
                  right: -75,
                  child: _BackgroundGlow(
                    size: 210,
                    color: Color(0x1A1A9B78),
                  ),
                ),
                const Positioned(
                  top: 330,
                  left: -95,
                  child: _BackgroundGlow(
                    size: 190,
                    color: Color(0x14F6C445),
                  ),
                ),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    14,
                    20,
                    isCompact ? 18 : 26,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<AllergyProvider>(
                        builder: (context, provider, _) {
                          return _HomeHeader(
                            firstName: _firstName(provider.userName),
                          );
                        },
                      ),
                      SizedBox(height: isCompact ? 20 : 26),
                      const _HeroTitle(),
                      SizedBox(height: isCompact ? 16 : 20),
                      _FoodScannerHero(
                        compact: isCompact,
                      ),
                      SizedBox(height: isCompact ? 18 : 22),
                      _ImageActionButton(
                        icon: Icons.photo_library_rounded,
                        title: 'Pilih dari Galeri',
                        subtitle:
                            'Gunakan foto makanan yang tersimpan',
                        colors: const [
                          Color(0xFF087D64),
                          Color(0xFF13A17E),
                        ],
                        onTap: () => _pickImage(
                          context,
                          ImageSource.gallery,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ImageActionButton(
                        icon: Icons.camera_alt_rounded,
                        title: 'Ambil Foto Makanan',
                        subtitle:
                            'Gunakan kamera untuk analisis langsung',
                        colors: const [
                          Color(0xFFF0B82F),
                          Color(0xFFF7C84C),
                        ],
                        foregroundColor: const Color(0xFF49350A),
                        onTap: () => _pickImage(
                          context,
                          ImageSource.camera,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer<AllergyProvider>(
                        builder: (context, provider, _) {
                          return _AllergyProfileCard(
                            allergyCount:
                                provider.selectedAllergies.length,
                            onTap: () =>
                                _openAllergyProfile(context),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        children: [
          Text(
            'Analyze your meal',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 29,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'with one click!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 29,
              height: 1.08,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              color: AppTheme.primary,
            ),
          ),
          SizedBox(height: 9),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 22),
          //   child: Text(
          //     'Deteksi bahan makanan dan risiko alergi secara cepat dengan bantuan AI.',
          //     textAlign: TextAlign.center,
          //     style: TextStyle(
          //       fontSize: 13,
          //       height: 1.45,
          //       color: AppTheme.textSecondary,
          //       fontWeight: FontWeight.w500,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String firstName;

  const _HomeHeader({
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BrandLogo(),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NootriScan',
                style: TextStyle(
                  fontSize: 21,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: AppTheme.primary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Smart Food Allergen Detection',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.045),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Halo,',
                style: TextStyle(
                  fontSize: 10,
                  height: 1,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '$firstName!',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF20B58B),
            Color(0xFF056A58),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.12),
          border: Border.all(
            color: Colors.white.withOpacity(0.62),
          ),
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.crop_free_rounded,
              color: Colors.white,
              size: 31,
            ),
            Icon(
              Icons.restaurant_rounded,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FUTURISTIC FOOD SCANNER HERO
// ─────────────────────────────────────────────────────────────────────────────

class _FoodScannerHero extends StatefulWidget {
  final bool compact;

  const _FoodScannerHero({
    required this.compact,
  });

  @override
  State<_FoodScannerHero> createState() =>
      _FoodScannerHeroState();
}

class _FoodScannerHeroState extends State<_FoodScannerHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final heroHeight = widget.compact ? 240.0 : 270.0;

    return Container(
      width: double.infinity,
      height: heroHeight,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF72E5C1),
            Color(0xFFFFFFFF),
            Color(0xFFF7D46B),
          ],
          stops: [0, 0.56, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF087D64).withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/nootriscan_food_scanner.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),

            // True-vector futuristic overlay.
            IgnorePointer(
              child: SvgPicture.asset(
                'assets/images/nootriscan_scanner_overlay.svg',
                fit: BoxFit.cover,
              ),
            ),

            // Dark-to-transparent overlay improves chip readability.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Color(0x52003429),
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            // Animated scan beam.
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, _) {
                final top =
                    52 + (_scanController.value * (heroHeight - 105));

                return Positioned(
                  top: top,
                  left: 20,
                  right: 20,
                  child: IgnorePointer(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFF53F6C6),
                            Colors.white,
                            Color(0xFF53F6C6),
                            Colors.transparent,
                          ],
                          stops: [0, 0.32, 0.5, 0.68, 1],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF41DBAE)
                                .withOpacity(0.75),
                            blurRadius: 15,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Top glass controls.
            // Positioned(
            //   top: 13,
            //   left: 13,
            //   right: 13,
            //   child: Row(
            //     children: [
            //       const _GlassStatusChip(
            //         icon: Icons.auto_awesome_rounded,
            //         label: 'AI FOOD SCAN',
            //         strong: true,
            //       ),
            //       const Spacer(),
            //       _GlassStatusChip(
            //         leading: const _LiveDot(),
            //         label: 'Scanning Ready',
            //       ),
            //     ],
            //   ),
            // ),

            // Bottom feature label.
            Positioned(
              left: 13,
              bottom: 13,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 10,
                    sigmaY: 10,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xB9065748),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.32),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.center_focus_strong_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Multi-object allergen detection',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              right: 13,
              bottom: 13,
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xE60A7C64),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.65),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF087D64)
                          .withOpacity(0.28),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassStatusChip extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final bool strong;

  const _GlassStatusChip({
    this.icon,
    this.leading,
    required this.label,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 11,
          sigmaY: 11,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: strong
                ? const Color(0xD9076E59)
                : Colors.white.withOpacity(0.78),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: strong
                  ? Colors.white.withOpacity(0.38)
                  : AppTheme.primary.withOpacity(0.16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) leading!,
              if (icon != null)
                Icon(
                  icon,
                  size: 13,
                  color:
                      strong ? Colors.white : AppTheme.primary,
                ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.2,
                  letterSpacing: strong ? 0.55 : 0,
                  fontWeight: FontWeight.w800,
                  color:
                      strong ? Colors.white : AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF20B58B),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF20B58B).withOpacity(0.7),
            blurRadius: 7,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class _ImageActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _ImageActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.24),
                blurRadius: 15,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                child: Icon(
                  icon,
                  color: foregroundColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: foregroundColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color:
                            foregroundColor.withOpacity(0.78),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: foregroundColor,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ALLERGY PROFILE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _AllergyProfileCard extends StatelessWidget {
  final int allergyCount;
  final VoidCallback onTap;

  const _AllergyProfileCard({
    required this.allergyCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasProfile = allergyCount > 0;

    final backgroundColor = hasProfile
        ? const Color(0xFFEAF8F2)
        : const Color(0xFFFFF8E4);

    final borderColor = hasProfile
        ? const Color(0xFFB8E7D6)
        : const Color(0xFFF4D98A);

    final iconColor = hasProfile
        ? AppTheme.primary
        : const Color(0xFFE2A817);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  hasProfile
                      ? Icons.verified_user_rounded
                      : Icons.warning_amber_rounded,
                  color: iconColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasProfile
                          ? 'Profil alergi sudah aktif'
                          : 'Profil alergi belum diatur',
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasProfile
                          ? '$allergyCount jenis alergi akan dicocokkan dengan hasil deteksi.'
                          : 'Atur profil agar peringatan sesuai dengan kondisi Anda.',
                      style: const TextStyle(
                        fontSize: 10.8,
                        height: 1.35,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: iconColor,
                  size: 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundGlow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
