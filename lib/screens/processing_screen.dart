import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/allergy_provider.dart';
import '../providers/analysis_provider.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final File? imageFile;

  /// true untuk menggunakan data simulasi.
  final bool useMock;

  const ProcessingScreen({
    super.key,
    this.imageFile,
    this.useMock = false,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;
  late final AnimationController _scanController;

  late final Animation<double> _pulseAnimation;

  Timer? _stageTimer;

  final List<_ProcessingStage> _stages = const [
    _ProcessingStage(
      title: 'Menyiapkan gambar',
      description: 'Menyesuaikan ukuran dan kualitas citra',
      icon: Icons.image_search_rounded,
      progress: 0.22,
    ),
    _ProcessingStage(
      title: 'Mengidentifikasi bahan',
      description: 'Model DETR sedang memindai hidangan',
      icon: Icons.center_focus_strong_rounded,
      progress: 0.48,
    ),
    _ProcessingStage(
      title: 'Mencocokkan profil alergi',
      description: 'Membandingkan bahan dengan profil Anda',
      icon: Icons.health_and_safety_rounded,
      progress: 0.74,
    ),
    _ProcessingStage(
      title: 'Menyusun hasil analisis',
      description: 'Menyiapkan informasi dan peringatan alergi',
      icon: Icons.auto_awesome_rounded,
      progress: 0.92,
    ),
  ];

  int _currentStage = 0;

  bool _isAnalyzing = false;
  bool _isCancelled = false;
  bool _hasError = false;

  String _errorMessage =
      'Analisis tidak dapat diselesaikan. Silakan coba kembali.';

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _startStageAnimation();

    // Analisis hanya dipanggil satu kali setelah frame pertama selesai.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnalysis();
    });
  }

  void _startStageAnimation() {
    _stageTimer?.cancel();

    if (mounted) {
      setState(() {
        _currentStage = 0;
      });
    }

    _stageTimer = Timer.periodic(
      const Duration(milliseconds: 1400),
      (timer) {
        if (!mounted || _hasError) {
          timer.cancel();
          return;
        }

        if (_currentStage < _stages.length - 1) {
          setState(() {
            _currentStage++;
          });
        } else {
          timer.cancel();
        }
      },
    );
  }

  Future<void> _startAnalysis() async {
    if (_isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _hasError = false;
      _isCancelled = false;
    });

    final allergyProvider = context.read<AllergyProvider>();
    final analysisProvider = context.read<AnalysisProvider>();

    try {
      if (widget.useMock || widget.imageFile == null) {
        await analysisProvider.analyzeMock(
          allergyProvider,
          withAllergen: true,
        );
      } else {
        await analysisProvider.analyzeImage(
          widget.imageFile!,
          allergyProvider,
        );
      }

      if (!mounted || _isCancelled) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            imageFile: widget.imageFile,
          ),
        ),
      );
    } catch (error) {
      if (!mounted || _isCancelled) return;

      _stageTimer?.cancel();

      setState(() {
        _isAnalyzing = false;
        _hasError = true;
        _errorMessage = _getReadableError(error);
      });
    }
  }

  String _getReadableError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('socket') ||
        message.contains('connection') ||
        message.contains('network')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }

    if (message.contains('timeout')) {
      return 'Waktu pemrosesan terlalu lama. Silakan coba kembali.';
    }

    return 'Analisis tidak dapat diselesaikan. Silakan coba kembali.';
  }

  void _retryAnalysis() {
    _startStageAnimation();
    _startAnalysis();
  }

  void _cancelAnalysis() {
    _isCancelled = true;

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    _rotationController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_currentStage];

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          _isCancelled = true;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF071712),
        body: Stack(
          children: [
            _buildBackground(),
            _buildDecorativeGlow(),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  children: [
                    _buildHeader(),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 30,
                            bottom: 20,
                          ),
                          child: Column(
                            children: [
                              _buildScannerCard(stage),
                              const SizedBox(height: 22),
                              _buildStageIndicator(),
                            ],
                          ),
                        ),
                      ),
                    ),

                    _hasError
                        ? _buildErrorActions()
                        : _buildCancelButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.imageFile != null)
            Image.file(
              widget.imageFile!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const SizedBox.shrink();
              },
            ),

          if (widget.imageFile != null)
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 22,
                sigmaY: 22,
              ),
              child: Container(
                color: Colors.black.withOpacity(0.42),
              ),
            ),

          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF071712).withOpacity(0.88),
                  const Color(0xFF0A211A).withOpacity(0.94),
                  const Color(0xFF06110E),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeGlow() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -90,
              child: _GlowCircle(
                size: 250,
                color: AppTheme.primary.withOpacity(0.14),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -110,
              child: _GlowCircle(
                size: 280,
                color: const Color(0xFF68D6B3).withOpacity(0.09),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          child: const Icon(
            Icons.document_scanner_outlined,
            color: Color(0xFF8AE1C3),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NootriScan AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Analisis bahan makanan',
                style: TextStyle(
                  color: Color(0xFF8BA99F),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1D5947).withOpacity(0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF65C5A5).withOpacity(0.25),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LiveDot(),
              SizedBox(width: 7),
              Text(
                'AI Aktif',
                style: TextStyle(
                  color: Color(0xFF9CE5CC),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScannerCard(_ProcessingStage stage) {
    return _GlassContainer(
      borderRadius: 30,
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 24),
      child: Column(
        children: [
          _buildScanner(),
          const SizedBox(height: 32),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Column(
              key: ValueKey(_hasError ? 'error' : _currentStage),
              children: [
                Icon(
                  _hasError
                      ? Icons.error_outline_rounded
                      : stage.icon,
                  color: _hasError
                      ? const Color(0xFFFF8B8B)
                      : const Color(0xFF86DDBF),
                  size: 25,
                ),
                const SizedBox(height: 10),
                Text(
                  _hasError
                      ? 'Analisis terhenti'
                      : stage.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _hasError
                      ? _errorMessage
                      : stage.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.58),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          _buildProgressBar(stage.progress),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _hasError
                    ? 'Proses dihentikan'
                    : 'Tahap ${_currentStage + 1} dari ${_stages.length}',
                style: const TextStyle(
                  color: Color(0xFF78988D),
                  fontSize: 11,
                ),
              ),
              Text(
                _hasError
                    ? 'Gagal'
                    : '${(stage.progress * 100).round()}%',
                style: TextStyle(
                  color: _hasError
                      ? const Color(0xFFFF8B8B)
                      : const Color(0xFF9CE5CC),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    return SizedBox(
      width: 280,
      height: 280,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 224,
              height: 224,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.20),
                    blurRadius: 50,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),

          AnimatedBuilder(
            animation: _rotationController,
            builder: (_, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(244, 244),
                  painter: _ScannerRingPainter(
                    color: _hasError
                        ? const Color(0xFFFF7B7B)
                        : const Color(0xFF62D3AD),
                  ),
                ),
              );
            },
          ),

          Container(
            width: 194,
            height: 194,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF75DEBB),
                  Color(0xFF225A49),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildFoodImage(),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0C382B).withOpacity(0.26),
                        ],
                      ),
                    ),
                  ),

                  if (!_hasError)
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (_, __) {
                        return Positioned(
                          top: 15 + (_scanController.value * 154),
                          left: 18,
                          right: 18,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Color(0xFFB5FFE7),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7FFFD4)
                                      .withOpacity(0.85),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          _buildCenterAiBadge(),

          const _ScannerBadge(
            label: 'Bentuk',
            icon: Icons.category_outlined,
            top: 4,
            left: -2,
          ),
          const _ScannerBadge(
            label: 'Tekstur',
            icon: Icons.texture_rounded,
            top: 34,
            right: -12,
          ),
          const _ScannerBadge(
            label: 'Warna',
            icon: Icons.palette_outlined,
            bottom: 24,
            left: -8,
          ),
          const _ScannerBadge(
            label: 'Alergen',
            icon: Icons.health_and_safety_outlined,
            bottom: -2,
            right: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildFoodImage() {
    if (widget.imageFile != null) {
      return Image.file(
        widget.imageFile!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _buildImagePlaceholder();
        },
      );
    }

    return _buildImagePlaceholder();
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFF173A30),
      alignment: Alignment.center,
      child: const Text(
        '🍜',
        style: TextStyle(fontSize: 76),
      ),
    );
  }

  Widget _buildCenterAiBadge() {
    return Container(
      width: 67,
      height: 67,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF4FFFB).withOpacity(0.96),
        border: Border.all(
          color: const Color(0xFFC9F7E7),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: _hasError
          ? const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFE65E5E),
              size: 30,
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.primary,
                  size: 22,
                ),
                SizedBox(height: 2),
                Text(
                  'AI SCAN',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 8,
        color: Colors.white.withOpacity(0.07),
        child: TweenAnimationBuilder<double>(
          tween: Tween(
            begin: 0,
            end: _hasError ? 0 : progress,
          ),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF2CA47E),
                        Color(0xFF89E8C8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF61D7AF)
                            .withOpacity(0.35),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStageIndicator() {
    return _GlassContainer(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
      child: Row(
        children: List.generate(
          _stages.length,
          (index) {
            final isCompleted = index < _currentStage;
            final isActive = index == _currentStage;

            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isActive ? 36 : 30,
                          height: isActive ? 36 : 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted || isActive
                                ? const Color(0xFF2C9C79)
                                : Colors.white.withOpacity(0.07),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFF9BE7CE)
                                  : Colors.white.withOpacity(0.08),
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF56CDA5)
                                          .withOpacity(0.30),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check_rounded
                                : _stages[index].icon,
                            color: isCompleted || isActive
                                ? Colors.white
                                : const Color(0xFF68867C),
                            size: isActive ? 18 : 15,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive
                                ? const Color(0xFF9BE7CE)
                                : const Color(0xFF68867C),
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (index < _stages.length - 1)
                    Container(
                      width: 12,
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 17),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: index < _currentStage
                            ? const Color(0xFF4FC39C)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _cancelAnalysis,
        icon: const Icon(
          Icons.close_rounded,
          size: 18,
        ),
        label: const Text('Batalkan Analisis'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white.withOpacity(0.82),
          side: BorderSide(
            color: Colors.white.withOpacity(0.16),
          ),
          backgroundColor: Colors.white.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _cancelAnalysis,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(
                color: Colors.white.withOpacity(0.16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text('Kembali'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _retryAnalysis,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
            ),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProcessingStage {
  final String title;
  final String description;
  final IconData icon;
  final double progress;

  const _ProcessingStage({
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
  });
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const _GlassContainer({
    required this.child,
    required this.padding,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 16,
          sigmaY: 16,
        ),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(0xFF153229).withOpacity(0.60),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.09),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ScannerBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const _ScannerBadge({
    required this.label,
    required this.icon,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8,
            sigmaY: 8,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFFF9).withOpacity(0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withOpacity(0.70),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: AppTheme.primary,
                  size: 13,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF214B3E),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerRingPainter extends CustomPainter {
  final Color color;

  const _ScannerRingPainter({
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width / 2 - 10;

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      center,
      radius,
      backgroundPaint,
    );

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final gradientPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          color.withOpacity(0.15),
          color,
          color.withOpacity(0.15),
          Colors.transparent,
        ],
        stops: const [
          0.0,
          0.18,
          0.42,
          0.68,
          1.0,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 1.65,
      false,
      gradientPaint,
    );

    final tickPaint = Paint()
      ..color = color.withOpacity(0.48)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int index = 0; index < 24; index++) {
      final angle = (2 * math.pi / 24) * index;

      final outer = Offset(
        center.dx + math.cos(angle) * (radius + 1),
        center.dy + math.sin(angle) * (radius + 1),
      );

      final inner = Offset(
        center.dx + math.cos(angle) * (radius - 6),
        center.dy + math.sin(angle) * (radius - 6),
      );

      canvas.drawLine(
        inner,
        outer,
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScannerRingPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: 45,
        sigmaY: 45,
      ),
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

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.45,
      end: 1,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF82E5C3),
        ),
      ),
    );
  }
}