import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/analysis_result.dart';
import 'allergy_provider.dart';

enum AnalysisState { idle, loading, success, error }

class AnalysisProvider extends ChangeNotifier {
  AnalysisState _state = AnalysisState.idle;
  AnalysisResult? _currentResult;
  List<AnalysisResult> _history = [];
  String _errorMessage = '';

  // ⚠️ Ganti dengan URL ngrok/API DETR Anda
  static const String _apiUrl =
      'https://debit-trustable-flap.ngrok-free.dev/predict';

  AnalysisState get state => _state;
  AnalysisResult? get currentResult => _currentResult;
  List<AnalysisResult> get history => _history;
  String get errorMessage => _errorMessage;

  AnalysisProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadHistory(user.uid);
      } else {
        _history = [];
        _currentResult = null;
        _state = AnalysisState.idle;
        notifyListeners();
      }
    });
  }

  String _historyKey(String uid) => 'analysis_history_$uid';

  // ─── SET CURRENT RESULT (untuk membuka dari history) ─────────────────
  void setCurrentResult(AnalysisResult result) {
    _currentResult = result;
    _state = AnalysisState.success;
    notifyListeners();
  }

  // ─── ANALYZE IMAGE ──────────────────────────────────────────────────
  Future<void> analyzeImage(
      File imageFile, AllergyProvider allergyProvider) async {
    _state = AnalysisState.loading;
    _errorMessage = '';
    notifyListeners();

    try {
      final detectedIngredients =
          await _callDetectionApi(imageFile, allergyProvider);

      _currentResult = AnalysisResult(
        id: const Uuid().v4(),
        imagePath: imageFile.path,
        ingredients: detectedIngredients,
        analyzedAt: DateTime.now(),
      );

      _state = AnalysisState.success;
    } catch (e) {
      _errorMessage = 'Gagal menganalisis gambar: $e';
      _state = AnalysisState.error;
    }

    notifyListeners();
  }

  // ─── CALL DETR API ───────────────────────────────────────────────────
  Future<List<DetectedIngredient>> _callDetectionApi(
    File imageFile,
    AllergyProvider allergyProvider,
  ) async {
    final request =
        http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path));

    final response =
        await request.send().timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      debugPrint('API Response: $body');
      final json = jsonDecode(body);

      final predictions = json['predictions'] as List? ?? [];

      final allIngredients = predictions.map((p) {
        final label = p['label'] as String? ?? '';
        final confidence =
            (p['confidence'] as num?)?.toDouble() ?? 0.0;
        final isAllergen =
            allergyProvider.isIngredientAllergen(label);

        return DetectedIngredient.fromJson({
          'name': _capitalize(label),
          'isAllergen': isAllergen,
          'confidence': confidence,
          'box': p['box'],
        });
      }).toList();

      return allIngredients;
    } else {
      throw Exception('API error: ${response.statusCode}');
    }
  }

  // ─── MOCK ANALYSIS ───────────────────────────────────────────────────
  Future<void> analyzeMock(AllergyProvider allergyProvider,
      {bool withAllergen = true}) async {
    _state = AnalysisState.loading;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));

    final List<DetectedIngredient> mockIngredients = withAllergen
        ? [
            DetectedIngredient(
              name: 'Udang',
              isAllergen:
                  allergyProvider.isIngredientAllergen('Udang'),
              confidence: 0.95,
            ),
            DetectedIngredient(
              name: 'Mie',
              isAllergen:
                  allergyProvider.isIngredientAllergen('Mie'),
              confidence: 0.88,
            ),
          ]
        : [
            DetectedIngredient(
              name: 'Ayam',
              isAllergen:
                  allergyProvider.isIngredientAllergen('Ayam'),
              confidence: 0.92,
            ),
            DetectedIngredient(
              name: 'Selada',
              isAllergen:
                  allergyProvider.isIngredientAllergen('Selada'),
              confidence: 0.87,
            ),
            DetectedIngredient(
              name: 'Tomat',
              isAllergen:
                  allergyProvider.isIngredientAllergen('Tomat'),
              confidence: 0.91,
            ),
          ];

    _currentResult = AnalysisResult(
      id: const Uuid().v4(),
      imagePath: '',
      ingredients: mockIngredients,
      analyzedAt: DateTime.now(),
    );

    _state = AnalysisState.success;
    notifyListeners();
  }

  // ─── SAVE TO HISTORY ─────────────────────────────────────────────────
  Future<void> saveCurrentResult(String foodName) async {
    if (_currentResult == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _currentResult!.foodName = foodName;
    _currentResult!.isSaved = true;

    _history.insert(0, _currentResult!);
    await _saveHistory(uid);
    notifyListeners();
  }

  // ─── CLEAR ALL HISTORY ───────────────────────────────────────────────
  Future<void> clearHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _history.clear();
    await _saveHistory(uid);
    notifyListeners();
  }

  // ─── DELETE ONE ITEM ─────────────────────────────────────────────────
  Future<void> deleteHistoryItem(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _history.removeWhere((h) => h.id == id);
    await _saveHistory(uid);
    notifyListeners();
  }

  void resetState() {
    _state = AnalysisState.idle;
    _currentResult = null;
    notifyListeners();
  }

  // ─── PERSIST ─────────────────────────────────────────────────────────
  Future<void> _saveHistory(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _historyKey(uid),
      jsonEncode(_history.map((h) => h.toJson()).toList()),
    );
  }

  Future<void> _loadHistory(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final savedJson = prefs.getString(_historyKey(uid));

    if (savedJson != null) {
      try {
        final List decoded = jsonDecode(savedJson);
        _history =
            decoded.map((j) => AnalysisResult.fromJson(j)).toList();
      } catch (_) {
        _history = [];
      }
    } else {
      _history = [];
    }

    notifyListeners();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}