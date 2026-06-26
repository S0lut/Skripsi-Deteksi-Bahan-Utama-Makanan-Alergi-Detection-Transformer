import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/allergy_item.dart';

class AllergyProvider extends ChangeNotifier {
  List<AllergyItem> _allergyItems = AllergyItem.defaultItems;
  String _userName = '';
  bool _isLoaded = false;
  bool _isProfileComplete = false;

  List<AllergyItem> get allergyItems => _allergyItems;
  String get userName => _userName;
  bool get isLoaded => _isLoaded;
  bool get isProfileComplete => _isProfileComplete;

  List<AllergyItem> get selectedAllergies =>
      _allergyItems.where((item) => item.isSelected).toList();

  AllergyProvider() {
    // Listen ke perubahan auth — reload profil saat user berganti
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _isLoaded = false;
      _isProfileComplete = false;
      _userName = '';
      _allergyItems = AllergyItem.defaultItems;
      if (user != null) {
        _loadFromPrefs(user.uid);
      } else {
        _isLoaded = true;
        notifyListeners();
      }
    });
  }

  // ── Key pakai UID supaya tiap akun punya data sendiri ──────────────
  String _keyName(String uid) => 'user_name_$uid';
  String _keyComplete(String uid) => 'profile_complete_$uid';
  String _keyAllergy(String uid) => 'allergy_items_$uid';

  Future<void> _loadFromPrefs(String uid) async {
    final prefs = await SharedPreferences.getInstance();

    _userName = prefs.getString(_keyName(uid)) ?? '';
    _isProfileComplete = prefs.getBool(_keyComplete(uid)) ?? false;

    final savedJson = prefs.getString(_keyAllergy(uid));
    if (savedJson != null) {
      try {
        final List decoded = jsonDecode(savedJson);
        final loaded =
            decoded.map((j) => AllergyItem.fromJson(j)).toList();
        // Merge: pakai isSelected dari data lama, base dari defaultItems
        _allergyItems = AllergyItem.defaultItems.map((def) {
          final old = loaded.firstWhere(
            (l) => l.id == def.id,
            orElse: () => def,
          );
          return def.copyWith(isSelected: old.isSelected);
        }).toList();
      } catch (_) {
        _allergyItems = AllergyItem.defaultItems;
        await prefs.remove(_keyAllergy(uid));
      }
    } else {
      _allergyItems = AllergyItem.defaultItems;
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> saveToPrefs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName(uid), _userName);
    await prefs.setBool(_keyComplete(uid), true);
    await prefs.setString(
      _keyAllergy(uid),
      jsonEncode(_allergyItems.map((i) => i.toJson()).toList()),
    );
    _isProfileComplete = true;
  }

  void toggleAllergy(String id) {
    final idx = _allergyItems.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _allergyItems[idx] = _allergyItems[idx].copyWith(
        isSelected: !_allergyItems[idx].isSelected,
      );
      notifyListeners();
    }
  }

  void clearAllAllergies() {
    _allergyItems =
        _allergyItems.map((i) => i.copyWith(isSelected: false)).toList();
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  Future<void> saveProfile() async {
    await saveToPrefs();
    notifyListeners();
  }

  bool isIngredientAllergen(String ingredientName) {
    final nameLower = ingredientName.toLowerCase();
    return selectedAllergies.any(
      (a) =>
          nameLower.contains(a.name.toLowerCase()) ||
          a.name.toLowerCase().contains(nameLower),
    );
  }

  // Reset saat logout
  void reset() {
    _allergyItems = AllergyItem.defaultItems;
    _userName = '';
    _isLoaded = false;
    _isProfileComplete = false;
    notifyListeners();
  }
}