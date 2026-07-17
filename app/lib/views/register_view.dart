import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  static const _primary = Color(0xFF8B7CFF);
  static const _accent = Color(0xFF63E6FF);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _signUp(AuthViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await vm.signUp(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аккаунт создан. Теперь войдите.')),
      );
      Navigator.of(context).pop();
    } else if (vm.errorMessage != null) {
      _showSnackBar(vm.errorMessage!);
      vm.clearError();
    }
  }

  Future<void> _signInWithGoogle(AuthViewModel vm) async {
    final ok = await vm.signInWithGoogle();

    if (!mounted) return;

    if (!ok && vm.errorMessage != null) {
      _showSnackBar(vm.errorMessage!);
      vm.clearError();
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      body: Stack(
        children: [
          const _AuthBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141B2D).withOpacity(0.88),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.28),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                              ),
                              const SizedBox(width: 4),
                              const Expanded(
                                child: Text(
                                  'Создать аккаунт',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Присоединяйся к Kolyas Messenger и общайся в одном стиле.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFFB6BED8),
                                  height: 1.5,
                                ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'example@gmail.com',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (v) {
                              if (v == null || !v.contains('@')) {
                                return 'Введите корректный email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              hintText: 'Минимум 6 символов',
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 6) {
                                return 'Минимум 6 символов';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscurePassword,
                            decoration: const InputDecoration(
                              labelText: 'Подтвердите пароль',
                              hintText: 'Повторите пароль',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                            ),
                            validator: (v) {
                              if (v != _passwordController.text) {
                                return 'Пароли не совпадают';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          FilledButton(
                            onPressed: vm.isLoading ? null : () => _signUp(vm),
                            child: vm.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Зарегистрироваться'),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.white.withOpacity(0.08)),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'или',
                                  style: TextStyle(color: Color(0xFFB6BED8)),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.white.withOpacity(0.08)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: vm.isLoading ? null : () => _signInWithGoogle(vm),
                            icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                            label: const Text('Войти через Google'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A1020),
            Color(0xFF111A31),
            Color(0xFF1D1840),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _glow(const Color(0xFF8B7CFF).withOpacity(0.22), 220),
          ),
          Positioned(
            left: -30,
            top: 180,
            child: _glow(const Color(0xFF63E6FF).withOpacity(0.14), 180),
          ),
          Positioned(
            bottom: -70,
            right: 10,
            child: _glow(const Color(0xFF8B7CFF).withOpacity(0.14), 240),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 18,
          ),
        ],
      ),
    );
  }
}