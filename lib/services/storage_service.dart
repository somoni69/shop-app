// lib/services/storage_service.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../locator.dart';

class StorageService {
  final SupabaseClient _supabase = getIt<SupabaseClient>();

  /// Загружает НЕСКОЛЬКО изображений товара
  Future<List<String>> uploadMultipleProductImages(List<File> images) async {
    final List<String> uploadedUrls = [];
    final String userId = _supabase.auth.currentUser!.id;
    try {
      for (final image in images) {
        final String fileExtension = image.path.split('.').last;
        final String fileName = '${const Uuid().v4()}.$fileExtension';

        // --- ИСПРАВЛЕНИЕ ЗДЕСЬ ---
        // Убираем 'product_images/' из пути, чтобы он соответствовал RLS-политике
        final String uploadPath = '$userId/$fileName';
        // (Было: 'product_images/$userId/$fileName')
        // --- КОНЕЦ ИСПРАВЛЕНИЯ ---

        await _supabase.storage.from('products').upload(uploadPath, image);
        final String publicUrl =
            _supabase.storage.from('products').getPublicUrl(uploadPath);
        uploadedUrls.add(publicUrl);
      }
      return uploadedUrls;
    } catch (e) {
      print('### Ошибка загрузки НЕСКОЛЬКИХ изображений: $e');
      throw Exception('Не удалось загрузить все изображения.');
    }
  }

  /// Загружает АВАТАР
  Future<String> uploadAvatar(File image) async {
    try {
      final String userId = _supabase.auth.currentUser!.id;
      final String fileExtension = image.path.split('.').last;
      final String fileName = 'avatar.$fileExtension';
      // Этот путь уже был правильным, он соответствует RLS-политике
      final String uploadPath = '$userId/$fileName';

      await _supabase.storage.from('avatars').upload(
            uploadPath,
            image,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true, // Перезаписать, если есть
            ),
          );

      final String publicUrl =
          _supabase.storage.from('avatars').getPublicUrl(uploadPath);

      final String uniqueUrl =
          '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      print('Аватар загружен: $uniqueUrl');
      return uniqueUrl;
    } catch (e) {
      print('### Ошибка загрузки аватара: $e');
      throw Exception('Не удалось загрузить аватар.');
    }
  }
}
