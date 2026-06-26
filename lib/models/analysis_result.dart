import 'package:flutter/material.dart';

class DetectedIngredient {
  final String name;
  final bool isAllergen;
  final double confidence;
  final Rect? boundingBox;

  DetectedIngredient({
    required this.name,
    required this.isAllergen,
    this.confidence = 0.0,
    this.boundingBox,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'isAllergen': isAllergen,
        'confidence': confidence,
        'boundingBox': boundingBox != null
            ? [
                boundingBox!.left,
                boundingBox!.top,
                boundingBox!.right,
                boundingBox!.bottom
              ]
            : null,
      };

  factory DetectedIngredient.fromJson(Map<String, dynamic> json) {
    Rect? parsedRect;

    final rawBox = json['boundingBox'] ?? json['box'];

    if (rawBox != null && rawBox is List && rawBox.length == 4) {
      parsedRect = Rect.fromLTRB(
        (rawBox[0] as num).toDouble(),
        (rawBox[1] as num).toDouble(),
        (rawBox[2] as num).toDouble(),
        (rawBox[3] as num).toDouble(),
      );
    }

    return DetectedIngredient(
      name: json['name'] ?? '',
      isAllergen: json['isAllergen'] ?? false,
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      boundingBox: parsedRect,
    );
  }
}

class AnalysisResult {
  final String id;
  final String imagePath;
  final List<DetectedIngredient> ingredients;
  final DateTime analyzedAt;
  String foodName;
  bool isSaved;

  AnalysisResult({
    required this.id,
    required this.imagePath,
    required this.ingredients,
    required this.analyzedAt,
    this.foodName = '',
    this.isSaved = false,
  });

  bool get hasAllergen => ingredients.any((i) => i.isAllergen);

  List<DetectedIngredient> get allergens =>
      ingredients.where((i) => i.isAllergen).toList();

  List<DetectedIngredient> get safeIngredients =>
      ingredients.where((i) => !i.isAllergen).toList();

  // ── Deduplikasi: hanya tampilkan nama unik, case-insensitive ──────────

  /// Nama alergen unik, tanpa duplikat.
  /// Contoh: [Udang, Udang, Telur] → "Udang, Telur"
  String get allergenSummary {
    final seen = <String>{};
    final unique = <String>[];
    for (final a in allergens) {
      final key = a.name.toLowerCase();
      if (seen.add(key)) unique.add(a.name);
    }
    return unique.join(', ');
  }

  /// Nama bahan unik, tanpa duplikat.
  /// Contoh: [Udang, Udang, Mie, Mie] → "Udang, Mie"
  String get ingredientSummary {
    final seen = <String>{};
    final unique = <String>[];
    for (final i in ingredients) {
      final key = i.name.toLowerCase();
      if (seen.add(key)) unique.add(i.name);
    }
    return unique.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'analyzedAt': analyzedAt.toIso8601String(),
        'foodName': foodName,
        'isSaved': isSaved,
      };

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        id: json['id'],
        imagePath: json['imagePath'],
        ingredients: (json['ingredients'] as List)
            .map((i) => DetectedIngredient.fromJson(i))
            .toList(),
        analyzedAt: DateTime.parse(json['analyzedAt']),
        foodName: json['foodName'] ?? '',
        isSaved: json['isSaved'] ?? false,
      );
}