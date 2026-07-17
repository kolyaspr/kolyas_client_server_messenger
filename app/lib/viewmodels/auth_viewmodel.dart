import 'dart:async';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AuthViewModel extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _authSubscription;

  void listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = _service.onAuthStateChange().listen((user) async {
      if (user != null) {
        try {
          await _service.upsertUser(user.id, user.email ?? '');
        } catch (e) {
          debugPrint('upsertUser error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signUp(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _service.signUp(email.trim(), password);
      if (response.user != null) {
        return true;
      }
      _setError('Не удалось создать аккаунт');
      return false;
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _service.signIn(email.trim(), password);
      if (response.session != null) {
        return true;
      }
      _setError('Вход не выполнен');
      return false;
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);

    try {
      await _service.signInWithGoogle();
      return true;
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      await _service.signOut();
    } on Exception catch (e) {
      _setError(_friendlyError(e.toString()));
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('Invalid login credentials')) {
      return 'Неверный email или пароль';
    }
    if (raw.contains('User already registered')) {
      return 'Пользователь с таким email уже существует';
    }
    if (raw.contains('Password should be at least')) {
      return 'Пароль должен быть не менее 6 символов';
    }
    return 'Ошибка: $raw';
  }
}