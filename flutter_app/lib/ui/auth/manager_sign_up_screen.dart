import 'package:flutter/material.dart';

import '../../data/model/farm_user.dart';
import '../../data/repository/auth_repository.dart';

class ManagerSignUpScreen extends StatefulWidget {
  const ManagerSignUpScreen({required this.authRepository, super.key});

  final AuthRepository authRepository;

  @override
  State<ManagerSignUpScreen> createState() => _ManagerSignUpScreenState();
}

class _ManagerSignUpScreenState extends State<ManagerSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await widget.authRepository.signUpManager(
        fullName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
        password: _passwordController.text,
      );
      if (mounted) Navigator.of(context).pop<FarmUser?>(user);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              widget.authRepository.errorMessage(error, signingUp: true),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manager sign up')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create manager account',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => (value?.trim().isNotEmpty ?? false)
                          ? null
                          : 'Enter your name.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration:
                          const InputDecoration(labelText: 'Email address'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) => (value?.contains('@') ?? false)
                          ? null
                          : 'Enter a valid email.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration:
                          const InputDecoration(labelText: 'Phone number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (value) => (value?.length ?? 0) >= 6
                          ? null
                          : 'Password must be at least 6 characters.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration:
                          const InputDecoration(labelText: 'Confirm password'),
                      obscureText: true,
                      validator: (value) => value == _passwordController.text
                          ? null
                          : 'Passwords do not match.',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _signUp,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
