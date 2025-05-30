// lib/services/theme_notifier.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ThemeNotifier extends ChangeNotifier {
  static const _kKeyIsDark = 'isDark';
  static const _kKeyBanner = 'bannerChoice';

  ThemeMode _themeMode = ThemeMode.light;
  Color _primaryColor = const Color(0xFF0096FF); // default blue

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;

  ThemeNotifier() {
    _init();
    // Listen for auth state changes to reset or reload theme
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        _resetToDefault();
      } else if (event == AuthChangeEvent.signedIn) {
        _init();
      }
    });
  }

  /// Initialize theme from local prefs and remote DB
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1) Restore dark/light
    _themeMode = prefs.getBool(_kKeyIsDark) == true
        ? ThemeMode.dark
        : ThemeMode.light;

    // 2) Restore bannerChoice → color from prefs
    await _loadBannerColor();

    // 3) Fetch latest bannerChoice from server and apply
    await _fetchRemoteBannerChoice();

    notifyListeners();
  }

  /// Load banner choice from SharedPreferences
  Future<void> _loadBannerColor() async {
    final prefs = await SharedPreferences.getInstance();
    final choice = prefs.getString(_kKeyBanner);
    _applyBannerChoice(choice, save: false);
  }

  /// Fetch banner choice from Supabase and persist/apply
  Future<void> _fetchRemoteBannerChoice() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final record = await Supabase.instance.client
          .from('userdata')
          .select('banner_choice')
          .eq('id', user.id)
          .single();
      final choice = (record as Map<String, dynamic>)['banner_choice'] as String?;

      // Persist locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kKeyBanner, choice ?? 'none');

      // Apply new color
      _applyBannerChoice(choice, save: false);
    } catch (e) {
      debugPrint('Error fetching remote banner choice: $e');
    }
  }

  /// Toggle light/dark and persist
  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await prefs.setBool(_kKeyIsDark, _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  /// Call this whenever bannerChoice changes locally
  Future<void> setBannerChoice(String? bannerChoice) async {
    // 1) Persist locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKeyBanner, bannerChoice ?? 'none');

    // 2) Apply to primaryColor
    _applyBannerChoice(bannerChoice, save: false);
    notifyListeners();
  }

  /// Apply banner choice to primary color
  void _applyBannerChoice(String? bannerChoice, {required bool save}) {
    switch (bannerChoice) {
      case 'soulhunter':
        _primaryColor = const Color(0xFFEE6E6D);
        break;
      case 'firefull_flyshine':
        _primaryColor = const Color(0xFFBEECDA);
        break;
      default:
        _primaryColor = const Color(0xFF0096FF);
    }
  }

  /// Reset to default when user logs out
  Future<void> _resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kKeyBanner);
    _themeMode = ThemeMode.light;
    _primaryColor = const Color(0xFF0096FF);
    await prefs.setBool(_kKeyIsDark, false);
    notifyListeners();
  }
}
