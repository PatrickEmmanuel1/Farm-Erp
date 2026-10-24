import 'package:flutter/material.dart';

import '../../data/model/farm_user.dart';
import '../../data/repository/auth_repository.dart';
import 'manager_sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.authRepository,
    required this.onSignedIn,
    super.key,
  });

  final AuthRepository authRepository;
  final ValueChanged<FarmUser> onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final user = await widget.authRepository.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) widget.onSignedIn(user);
    } catch (error) {
      if (mounted) {
        setState(() => _error = widget.authRepository.errorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openSignUp() async {
    final user = await Navigator.of(context).push<FarmUser?>(
      MaterialPageRoute(
        builder: (_) =>
            ManagerSignUpScreen(authRepository: widget.authRepository),
      ),
    );
    if (!mounted) return;
    if (user != null) {
      widget.onSignedIn(user);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check your email to confirm your new account.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Icon(
                      Icons.agriculture,
                      size: 54,
                      color: const Color(0xFF1F7A3D),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MyFarm',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D1D1D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to your farm account',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        color: const Color(0xFF3B3B3B),
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email address',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        return email.contains('@')
                            ? null
                            : 'Enter a valid email.';
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      validator: (value) => (value?.isNotEmpty ?? false)
                          ? null
                          : 'Enter your password.',
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFBF2D2D),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _busy ? null : _signIn,
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: _busy ? null : _openSignUp,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text(
                        'Create a manager account',
                        style: TextStyle(
                          color: Color(0xFFB83A3A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
