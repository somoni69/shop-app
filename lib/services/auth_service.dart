import 'package:supabase_flutter/supabase_flutter.dart';
// УДАЛИЛИ: import '../main.dart'; -> Нам больше не нужен main файл здесь!

class AuthService {
  // 1. Объявляем переменную для клиента Supabase внутри класса
  final SupabaseClient _supabase;

  // 2. Создаем конструктор.
  // Теперь, чтобы создать AuthService, кто-то ОБЯЗАН передать ему SupabaseClient.
  AuthService(this._supabase);

  // Вспомогательный геттер, чтобы не писать везде _supabase.auth
  // (это замена твоей строки final _supabaseAuth = supabase.auth)
  GoTrueClient get _auth => _supabase.auth;

  /// Стрим для отслеживания состояния входа
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Отправляет одноразовый код (OTP)
  Future<void> signInWithOtp(String email) async {
    try {
      // Используем наш геттер _auth (который берет данные из переданного _supabase)
      await _auth.signInWithOtp(
        email: email,
        shouldCreateUser: true,
      );
    } catch (e) {
      // Хорошая практика: логировать ошибку перед выбросом, например:
      // debugPrint('Ошибка входа: $e');
      throw Exception('Не удалось отправить код. Проверьте email.');
    }
  }

  /// Проверяет OTP
  Future<void> verifyOtp(String email, String token) async {
    try {
      await _auth.verifyOTP(
        type: OtpType.email,
        token: token,
        email: email,
      );
    } catch (e) {
      throw Exception('Неверный код или истекло время ожидания.');
    }
  }

  /// Выход из системы
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Получает текущего пользователя
  User? get currentUser => _auth.currentUser;
}