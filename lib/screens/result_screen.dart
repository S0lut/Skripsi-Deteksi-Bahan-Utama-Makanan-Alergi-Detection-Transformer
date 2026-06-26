import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/analysis_result.dart';
import '../providers/analysis_provider.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';

class ResultScreen extends StatelessWidget {
  final File? imageFile;
  final bool isFromHistory; // true = dibuka dari history, sembunyikan tombol Simpan

  const ResultScreen({
    super.key,
    this.imageFile,
    this.isFromHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisProvider>(
      builder: (context, provider, _) {
        final result = provider.currentResult;
        if (result == null) return const Scaffold();

        return result.hasAllergen
            ? _AllergyWarningView(
                result: result,
                imageFile: imageFile,
                isFromHistory: isFromHistory,
              )
            : _SafeResultView(
                result: result,
                imageFile: imageFile,
                isFromHistory: isFromHistory,
              );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// FUNGSI PENYARING DETEKSI
// Menyimpan satu confidence tertinggi untuk setiap nama objek.
// Contoh: Udang 50%, 60%, 70%, 80% -> hanya Udang 80% yang ditampilkan.
// Semua bounding box asli tetap ditampilkan pada gambar.
// ────────────────────────────────────────────────────────────────────────────
List<DetectedIngredient> _uniqueIngredients(
  List<DetectedIngredient> ingredients,
) {
  final Map<String, DetectedIngredient> highestByName = {};

  for (final ingredient in ingredients) {
    final key = ingredient.name.trim().toLowerCase();
    if (key.isEmpty) continue;

    final currentHighest = highestByName[key];
    if (currentHighest == null ||
        ingredient.confidence > currentHighest.confidence) {
      highestByName[key] = ingredient;
    }
  }

  final result = highestByName.values.toList();
  result.sort((a, b) {
    // Alergen ditampilkan terlebih dahulu, lalu berdasarkan confidence tertinggi.
    if (a.isAllergen != b.isAllergen) {
      return a.isAllergen ? -1 : 1;
    }
    return b.confidence.compareTo(a.confidence);
  });

  return result;
}

double _confidencePercent(double confidence) {
  final value = confidence <= 1 ? confidence * 100 : confidence;
  return value.clamp(0, 100).toDouble();
}

String _confidenceText(double confidence) {
  return '${_confidencePercent(confidence).round()}%';
}

// ────────────────────────────────────────────────────────────────────────────
// ALLERGY WARNING VIEW
// ────────────────────────────────────────────────────────────────────────────
class _AllergyWarningView extends StatelessWidget {
  final AnalysisResult result;
  final File? imageFile;
  final bool isFromHistory;

  const _AllergyWarningView({
    required this.result,
    this.imageFile,
    this.isFromHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueIngredients = _uniqueIngredients(result.ingredients);
    final uniqueAllergens = _uniqueIngredients(result.allergens);
    final allergenNamesStr = uniqueAllergens.map((a) => a.name).join(', ');

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F7),
      body: SafeArea(
        child: Column(
          children: [
            _AllergyHeader(
              allergenCount: uniqueAllergens.length,
              isFromHistory: isFromHistory,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: imageFile != null
                              ? ImageWithBoundingBoxes(
                                  imageFile: imageFile!,
                                  ingredients: result.ingredients,
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 250,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFECE9),
                                        Color(0xFFFFD8D2),
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '🍜',
                                      style: TextStyle(fontSize: 82),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _DetectionResultCard(
                          ingredients: uniqueIngredients,
                          allergenNames: allergenNamesStr,
                          foodName: isFromHistory ? result.foodName : '',
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            _ResultActionButtons(
              result: result,
              isFromHistory: isFromHistory,
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergyHeader extends StatelessWidget {
  final int allergenCount;
  final bool isFromHistory;
  final VoidCallback onBack;

  const _AllergyHeader({
    required this.allergenCount,
    required this.isFromHistory,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.danger,
            const Color(0xFFE53935),
            const Color(0xFFFF6258),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withOpacity(0.20),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isFromHistory) ...[
            _HeaderIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            ),
            const SizedBox(width: 10),
          ],

          // Ikon peringatan dipindahkan ke samping teks agar header lebih ringkas.
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE53935),
              size: 29,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOOTRISCAN',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Peringatan Alergi!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$allergenCount jenis alergen sesuai profil Anda terdeteksi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.90),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.26)),
            ),
            child: Text(
              '$allergenCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: Colors.white, size: 17),
        ),
      ),
    );
  }
}

class _DetectionResultCard extends StatelessWidget {
  final List<DetectedIngredient> ingredients;
  final String allergenNames;
  final String foodName;

  const _DetectionResultCard({
    required this.ingredients,
    required this.allergenNames,
    required this.foodName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFDFDB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9E2A21).withOpacity(0.11),
            blurRadius: 26,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (foodName.trim().isNotEmpty) ...[
            Text(
              foodName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
          ],
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8E5),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.manage_search_rounded,
                  color: Color(0xFFE53935),
                  size: 25,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hasil Deteksi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Skor tertinggi untuk setiap jenis objek',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${ingredients.length} objek',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ingredients.isEmpty)
            const _EmptyDetectionState()
          else
            ...ingredients.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == ingredients.length - 1 ? 0 : 10,
                    ),
                    child: _DetectedIngredientTile(
                      number: entry.key + 1,
                      ingredient: entry.value,
                    ),
                  ),
                ),
          const SizedBox(height: 16),
          _AllergyNotice(allergenNames: allergenNames),
        ],
      ),
    );
  }
}

class _DetectedIngredientTile extends StatelessWidget {
  final int number;
  final DetectedIngredient ingredient;

  const _DetectedIngredientTile({
    required this.number,
    required this.ingredient,
  });

  @override
  Widget build(BuildContext context) {
    final isAllergen = ingredient.isAllergen;
    final accentColor =
        isAllergen ? const Color(0xFFE53935) : const Color(0xFF169B69);
    final lightColor =
        isAllergen ? const Color(0xFFFFEFED) : const Color(0xFFEAF8F2);
    final percent = _confidencePercent(ingredient.confidence);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: accentColor.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          isAllergen
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAllergen ? 'Alergen profil Anda' : 'Bukan alergen profil',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.22),
                      blurRadius: 9,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _confidenceText(ingredient.confidence),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.9),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDetectionState extends StatelessWidget {
  const _EmptyDetectionState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Tidak ada objek yang dapat ditampilkan.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _AllergyNotice extends StatelessWidget {
  final String allergenNames;

  const _AllergyNotice({required this.allergenNames});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFE9E6), Color(0xFFFFF5F3)],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFFFC7C0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perlu diperhatikan',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB42318),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Makanan ini mengandung $allergenNames yang sesuai dengan profil alergi Anda. Hindari konsumsi dan periksa kembali komposisi makanan.',
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: Color(0xFF8F241B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultActionButtons extends StatelessWidget {
  final AnalysisResult result;
  final bool isFromHistory;

  const _ResultActionButtons({
    required this.result,
    required this.isFromHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (!isFromHistory) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showSaveDialog(context, result),
                icon: const Icon(Icons.bookmark_add_outlined, size: 19),
                label: const Text('Simpan Hasil'),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  isFromHistory ? Navigator.pop(context) : _goHome(context),
              icon: Icon(
                isFromHistory
                    ? Icons.arrow_back_rounded
                    : Icons.home_outlined,
                size: 19,
              ),
              label: Text(isFromHistory ? 'Kembali' : 'Kembali ke Awal'),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// SAFE RESULT VIEW
// ────────────────────────────────────────────────────────────────────────────
class _SafeResultView extends StatelessWidget {
  final AnalysisResult result;
  final File? imageFile;
  final bool isFromHistory;

  const _SafeResultView({
    required this.result,
    this.imageFile,
    this.isFromHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Row(
                children: [
                  // Tombol kembali jika dibuka dari history
                  if (isFromHistory) ...[
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.textPrimary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                  ],
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

            const Text(
              'Hasil Analisis',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),

            // Nama makanan jika dibuka dari history
            if (isFromHistory && result.foodName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                result.foodName,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ── Food Image With Bounding Boxes ───────────────────────
            if (imageFile != null)
              ImageWithBoundingBoxes(
                imageFile: imageFile!,
                ingredients: result.ingredients,
              )
            else
              Container(
                width: double.infinity,
                height: 250,
                color: const Color(0xFFF0FAF5),
                child: const Center(child: Text('🥗', style: TextStyle(fontSize: 90))),
              ),

            const SizedBox(height: 20),

            // ── Safe Message ─────────────────────────────────────────
            const Text(
              'tidak terdeteksi\nalergen',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Makanan ini aman untuk Anda konsumsi ✅',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),

            const Spacer(),

            // ── Action Buttons ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: Row(
                children: [
                  // Tombol Simpan hanya muncul jika BUKAN dari history
                  if (!isFromHistory) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showSaveDialog(context, result),
                        child: const Text('Simpan Hasil'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => isFromHistory
                          ? Navigator.pop(context)
                          : _goHome(context),
                      child: Text(isFromHistory ? 'Kembali' : 'Kembali ke Awal'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// SHARED WIDGET: MENGGAMBAR GAMBAR & KOTAK PREDIKSI SECARA AKURAT
// ────────────────────────────────────────────────────────────────────────────
class ImageWithBoundingBoxes extends StatefulWidget {
  final File imageFile;
  final List<DetectedIngredient> ingredients;

  const ImageWithBoundingBoxes({
    super.key,
    required this.imageFile,
    required this.ingredients,
  });

  @override
  State<ImageWithBoundingBoxes> createState() => _ImageWithBoundingBoxesState();
}

class _ImageWithBoundingBoxesState extends State<ImageWithBoundingBoxes> {
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  void _loadImageSize() {
    final image = FileImage(widget.imageFile);
    image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageSize = Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
      color: Colors.black87,
      child: _imageSize == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : LayoutBuilder(
              builder: (context, constraints) {
                final double imgW = _imageSize!.width;
                final double imgH = _imageSize!.height;
                final double widgetW = constraints.maxWidth;
                final double widgetH = constraints.maxHeight;

                final double imgRatio = imgW / imgH;
                final double widgetRatio = widgetW / widgetH;

                double drawW, drawH, dx, dy;
                if (widgetRatio > imgRatio) {
                  drawH = widgetH;
                  drawW = drawH * imgRatio;
                  dx = (widgetW - drawW) / 2;
                  dy = 0;
                } else {
                  drawW = widgetW;
                  drawH = drawW / imgRatio;
                  dx = 0;
                  dy = (widgetH - drawH) / 2;
                }

                return Stack(
                  children: [
                    Positioned(
                      left: dx, top: dy,
                      width: drawW, height: drawH,
                      child: Image.file(widget.imageFile, fit: BoxFit.fill),
                    ),
                    ...widget.ingredients
                        .where((i) => i.boundingBox != null)
                        .map((ingredient) {
                      final box = ingredient.boundingBox!;

                      double x1, y1, x2, y2;
                      if (box.left <= 1.0 && box.top <= 1.0 &&
                          box.right <= 1.0 && box.bottom <= 1.0) {
                        x1 = box.left * imgW;
                        y1 = box.top * imgH;
                        x2 = box.right * imgW;
                        y2 = box.bottom * imgH;
                      } else {
                        x1 = box.left;
                        y1 = box.top;
                        x2 = box.right;
                        y2 = box.bottom;
                      }

                      final double scaleX = drawW / imgW;
                      final double scaleY = drawH / imgH;

                      final double left   = dx + (x1 * scaleX);
                      final double top    = dy + (y1 * scaleY);
                      final double width  = (x2 - x1) * scaleX;
                      final double height = (y2 - y1) * scaleY;

                      final color = ingredient.isAllergen
                          ? AppTheme.danger
                          : AppTheme.primary;

                      return Positioned(
                        left: left, top: top,
                        width: width, height: height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: color, width: 2.5),
                                color: color.withOpacity(0.08),
                              ),
                            ),
                            Positioned(
                              top: -22, left: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${ingredient.isAllergen ? "⚠ " : ""}${ingredient.name} ${_confidenceText(ingredient.confidence)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Pindah Halaman & Dialog
// ────────────────────────────────────────────────────────────────────────────
void _showSaveDialog(BuildContext context, AnalysisResult result) {
  final controller = TextEditingController(text: result.foodName);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Beri nama makanan ini',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'cth: Mie Goreng Udang...',
                hintStyle: TextStyle(fontSize: 13, color: AppTheme.textHint),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () async {
                      final name = controller.text.trim().isEmpty
                          ? 'Makanan Tanpa Nama'
                          : controller.text.trim();
                      Navigator.pop(ctx);

                      await context
                          .read<AnalysisProvider>()
                          .saveCurrentResult(name);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Hasil disimpan ke Riwayat!'),
                            backgroundColor: AppTheme.primary,
                            duration: Duration(seconds: 2),
                          ),
                        );

                        context.read<AnalysisProvider>().resetState();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MainShell(initialIndex: 1)),
                          (route) => false,
                        );
                      }
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void _goHome(BuildContext context) {
  context.read<AnalysisProvider>().resetState();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => const MainShell()),
    (route) => false,
  );
}