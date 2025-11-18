import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../locator.dart'; // <-- Добавляем импорт локатора

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  
  // ИСПРАВЛЕНИЕ: Берем сервис через getIt
  final _authService = getIt<AuthService>();

  bool _isLoading = false;
  bool _isCodeSent = false;

  // ... Весь остальной код остается без изменений ...
  // Просто скопируй свои методы _sendCode, _verifyCode и build, 
  // они написаны верно.
  
  Future<void> _sendCode() async {
    if (_emailController.text.isEmpty || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithOtp(_emailController.text.trim());
      setState(() => _isCodeSent = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.isEmpty || _isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _authService.verifyOtp(
        _emailController.text.trim(),
        _codeController.text.trim(),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
     // Твой код build... (он у тебя правильный)
     return Scaffold(
      appBar: AppBar(title: const Text('Вход / Регистрация')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isCodeSent ? _buildCodeInput() : _buildEmailInput(),
          ),
        ),
      ),
    );
  }
  
  // Методы _buildEmailInput и _buildCodeInput у тебя отличные, оставляй их.
  Widget _buildEmailInput() {
    return Column(
      key: const ValueKey('emailInput'),
      children: [
        Text('Вход в ShopApp', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 24),
        if (_isLoading) const CircularProgressIndicator()
        else ElevatedButton(onPressed: _sendCode, child: const Text('Получить код')),
      ],
    );
  }

  Widget _buildCodeInput() {
    return Column(
      key: const ValueKey('codeInput'),
      children: [
        Text('Код отправлен на', style: Theme.of(context).textTheme.bodyLarge),
        Text(_emailController.text, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(labelText: 'Код из письма', prefixIcon: Icon(Icons.password)),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        const SizedBox(height: 24),
        if (_isLoading) const CircularProgressIndicator()
        else ElevatedButton(onPressed: _verifyCode, child: const Text('Подтвердить и войти')),
        TextButton(
          onPressed: _isLoading ? null : () => setState(() => _isCodeSent = false),
          child: const Text('Изменить email'),
        )
      ],
    );
  }
}