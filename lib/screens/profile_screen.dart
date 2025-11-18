// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../locator.dart'; // Для supabase
import '../services/storage_service.dart'; // Наш сервис

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storageService = StorageService();
  final _nameController = TextEditingController();
  final String _userId = getIt<SupabaseClient>().auth.currentUser!.id;

  bool _isLoading = true;
  String? _avatarUrl;
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  /// Загружает данные профиля из Supabase
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final data = await getIt<SupabaseClient>()
          .from('profiles')
          .select('full_name, avatar_url')
          .eq('id', _userId)
          .single();

      _nameController.text = (data['full_name'] as String?) ?? '';
      _avatarUrl = (data['avatar_url'] as String?);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки профиля: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Выбирает новое изображение для аватара
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  /// Сохраняет изменения профиля
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      String? newAvatarUrl = _avatarUrl;

      // 1. Если выбрано новое фото, загружаем его
      if (_pickedImage != null) {
        newAvatarUrl = await _storageService.uploadAvatar(_pickedImage!);
      }

      final newName = _nameController.text.trim();

      // 2. Обновляем запись в таблице 'profiles'
      await getIt<SupabaseClient>().from('profiles').update({
        'full_name': newName,
        'avatar_url': newAvatarUrl,
      }).eq('id', _userId);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Профиль сохранен!')));
        Navigator.of(context).pop(); // Возвращаемся назад
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка сохранения: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой профиль'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _pickedImage != null
                          ? FileImage(_pickedImage!)
                          : (_avatarUrl != null
                              ? NetworkImage(_avatarUrl!)
                              : null) as ImageProvider?,
                      child: (_pickedImage == null && _avatarUrl == null)
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Изменить фото'),
                    onPressed: _pickImage,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Ваше имя'),
                  ),
                ],
              ),
            ),
    );
  }
}
