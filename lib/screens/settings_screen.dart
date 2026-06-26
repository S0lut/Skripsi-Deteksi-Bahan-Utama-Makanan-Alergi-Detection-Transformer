import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/allergy_provider.dart';
import '../providers/auth_provider.dart' as ap;
import '../theme/app_theme.dart';
import 'allergy_profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth_wrapper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AllergyProvider>();
    _nameController = TextEditingController(text: provider.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final provider = context.read<AllergyProvider>();
    final name = _nameController.text.trim();
    provider.setUserName(name.isEmpty ? 'Pengguna' : name);
    await provider.saveProfile();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pengaturan disimpan!'),
          backgroundColor: AppTheme.primary,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

 Future<void> _logout() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: const Text('Keluar dari Akun?',
          style: TextStyle(fontWeight: FontWeight.w700)),
      content: const Text(
        'Anda akan keluar dari akun NootriScan.',
        style: TextStyle(fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Keluar',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );

  if (confirmed == true && mounted) {
    // 1. Reset provider lokal dulu
    context.read<AllergyProvider>().reset();

    // 2. Sign out Firebase → otomatis trigger StreamBuilder di AuthWrapper
    //    → AuthWrapper detect user == null → tampilkan LoginScreen
    await context.read<ap.AuthProvider>().signOut();

    // 3. Force navigate ke root untuk clear semua route stack
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
        (route) => false,
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FDF9),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 1.8),
                    ),
                    child: const Center(
                        child: Text('🍴', style: TextStyle(fontSize: 18))),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'NootriScan',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pengaturan',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary),
                    ),

                    const SizedBox(height: 16),

                    // ── Akun Card ──────────────────────────────────
                    Consumer<ap.AuthProvider>(
                      builder: (context, authProv, _) {
                        return _SettingsCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionLabel(
                                  icon: Icons.account_circle_outlined,
                                  label: 'Akun'),
                              const SizedBox(height: 12),
                              // Avatar + info
                              Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme.primaryLight,
                                      border: Border.all(
                                          color: AppTheme.primary, width: 2),
                                    ),
                                    child: authProv.userPhotoUrl.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              authProv.userPhotoUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Center(
                                                      child: Icon(
                                                          Icons.person,
                                                          color: AppTheme
                                                              .primary,
                                                          size: 26)),
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(Icons.person,
                                                color: AppTheme.primary,
                                                size: 26)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          authProv.userDisplayName.isNotEmpty
                                              ? authProv.userDisplayName
                                              : 'Pengguna NootriScan',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          authProv.userEmail.isNotEmpty
                                              ? authProv.userEmail
                                              : 'Tidak ada email',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textHint),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // ── Name Card ──────────────────────────────────
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(
                              icon: Icons.person_outline,
                              label: 'Nama Pengguna'),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Masukkan nama Anda...',
                              prefixIcon: const Icon(Icons.person_outline,
                                  color: AppTheme.primary),
                              filled: true,
                              fillColor: AppTheme.bgSecondary,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppTheme.borderDark),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppTheme.borderDark),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppTheme.primary, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _saveSettings,
                              child: const Text('Simpan Perubahan',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Allergy Profile Card ───────────────────────
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(
                              icon: Icons.warning_amber_outlined,
                              label: 'Profil Alergi'),
                          const SizedBox(height: 12),
                          Consumer<AllergyProvider>(
                            builder: (context, provider, _) {
                              final selected = provider.selectedAllergies;
                              if (selected.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text('⚠️',
                                          style: TextStyle(fontSize: 16)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Belum ada alergi dipilih',
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF795548)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selected
                                    .map((item) => Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryLight,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: AppTheme.primary
                                                    .withOpacity(0.3)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SvgPicture.asset(item.iconAsset,
                                                  width: 18, height: 18),
                                              const SizedBox(width: 5),
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.primaryDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AllergyProfileScreen()),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_outlined, size: 16),
                                  SizedBox(width: 6),
                                  Text('Edit Profil Alergi',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── App Info Card ──────────────────────────────
                    _SettingsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(
                              icon: Icons.info_outline,
                              label: 'Informasi Aplikasi'),
                          const SizedBox(height: 10),
                          const _InfoRow(
                              label: 'Versi Aplikasi', value: '1.00'),
                          const _InfoRow(
                              label: 'Developer', value: 'NootriScan Team'),
                          const _InfoRow(
                              label: 'Platform', value: 'iOS & Android'),
                          const _InfoRow(label: 'Model AI', value: 'DETR/Resnet-50'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── LOGOUT BUTTON ──────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF3F3),
                          foregroundColor: AppTheme.danger,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                                color: AppTheme.danger.withOpacity(0.3),
                                width: 1.5),
                          ),
                        ),
                        onPressed: _logout,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Keluar dari Akun',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final Widget child;
  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textHint,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
