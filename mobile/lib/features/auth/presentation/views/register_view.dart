import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRegister() {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
      ref.read(authViewModelProvider.notifier).register(
            email,
            username,
            password,
            fullName.isNotEmpty ? fullName : null,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Join VibeReel', style: AppTypography.headingLarge),
              const SizedBox(height: 8),
              const Text(
                'Connect with creators & share vertical videos',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.alternate_email, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name (Optional)',
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: authState.isLoading ? null : _onRegister,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
