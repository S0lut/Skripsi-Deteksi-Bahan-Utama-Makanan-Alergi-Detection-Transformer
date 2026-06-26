import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/analysis_result.dart';
import '../providers/analysis_provider.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary, width: 1.5),
                    ),
                    child: const Center(child: Text('🍴', style: TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'NootriScan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                'Riwayat Analisis',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
            ),

            // ── History List ─────────────────────────────────────────
            Expanded(
              child: Consumer<AnalysisProvider>(
                builder: (context, provider, _) {
                  if (provider.history.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📋', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text(
                            'Belum ada riwayat analisis.',
                            style: TextStyle(fontSize: 14, color: AppTheme.textHint),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Scan makanan pertama Anda!',
                            style: TextStyle(fontSize: 13, color: AppTheme.textHint),
                          ),
                        ],
                      ),
                    );
                  }

                  final grouped = _groupByDate(provider.history);

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final section = grouped[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              section['dateLabel'] as String,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textHint,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          ...(section['items'] as List<AnalysisResult>).map(
                            (result) => _HistoryCard(result: result),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // ── Clear Button ─────────────────────────────────────────
            Consumer<AnalysisProvider>(
              builder: (context, provider, _) {
                if (provider.history.isEmpty) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  decoration: const BoxDecoration(
                    color: AppTheme.bgPrimary,
                    border: Border(top: BorderSide(color: AppTheme.border)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => _confirmClear(context, provider),
                      child: const Text(
                        'Hapus Riwayat',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _groupByDate(List<AnalysisResult> history) {
    final Map<String, List<AnalysisResult>> grouped = {};
    final now = DateTime.now();

    for (final result in history) {
      final date = result.analyzedAt;
      String label;

      if (_isSameDay(date, now)) {
        label = 'HARI INI, ${DateFormat('d MMM yyyy | HH:mm', 'id_ID').format(date)}';
      } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
        label = 'KEMARIN, ${DateFormat('d MMM yyyy | HH:mm', 'id_ID').format(date)}';
      } else {
        label = DateFormat('d MMM yyyy | HH:mm', 'id_ID').format(date).toUpperCase();
      }

      grouped.putIfAbsent(label, () => []).add(result);
    }

    return grouped.entries
        .map((e) => {'dateLabel': e.key, 'items': e.value})
        .toList();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _confirmClear(BuildContext context, AnalysisProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus Semua Riwayat?'),
        content: const Text('Semua riwayat analisis akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final AnalysisResult result;

  const _HistoryCard({required this.result});

  // ── Navigasi ke ResultScreen dengan data dari history ──────────────────
  void _openResult(BuildContext context) {
    // Set currentResult di provider agar ResultScreen bisa membacanya
    context.read<AnalysisProvider>().setCurrentResult(result);

    // Ambil File gambar jika path masih valid
    final File? imageFile = result.imagePath.isNotEmpty &&
            File(result.imagePath).existsSync()
        ? File(result.imagePath)
        : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          imageFile: imageFile,
          isFromHistory: true, // flag agar tombol "Simpan" disembunyikan
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = result.imagePath.isNotEmpty &&
        File(result.imagePath).existsSync();

    return GestureDetector(
      onTap: () => _openResult(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 58, height: 58,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(result.imagePath),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Text(
                        result.hasAllergen ? '🍜' : '🥗',
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.foodName.isEmpty ? 'Makanan Tanpa Nama' : result.foodName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bahan Utama: ${result.ingredientSummary}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textHint),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Allergen Status',
                    style: TextStyle(fontSize: 11, color: AppTheme.textHint),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.hasAllergen ? '⚠️' : '✅',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          result.hasAllergen
                              ? 'Peringatan! (${result.allergenSummary})'
                              : 'Aman',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: result.hasAllergen ? AppTheme.danger : AppTheme.success,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete button
            IconButton(
              onPressed: () => context.read<AnalysisProvider>().deleteHistoryItem(result.id),
              icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textHint),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}