import 'package:supabase_flutter/supabase_flutter.dart';

String userFacingError(Object error, {bool signingUp = false}) {
  final rawMessage = error is AuthException
      ? error.message
      : error is PostgrestException
          ? error.message
          : error.toString();
  final message = rawMessage.toLowerCase();

  if (message.contains('email_not_confirmed')) {
    return 'Email not confirmed. Check your inbox and confirm your account.';
  }
  if (message.contains('invalid_credentials') ||
      message.contains('invalid login credentials') ||
      message.contains('invalid_grant')) {
    return 'Invalid email or password. Check your credentials and try again.';
  }
  if (message.contains('user_already_exists') ||
      message.contains('already registered')) {
    return 'An account with this email already exists. Please sign in instead.';
  }
  if (message.contains('password') && message.contains('at least')) {
    return 'Password must be at least 6 characters long.';
  }

  final cleanLine = rawMessage
      .split('\n')
      .firstWhere(
        (line) =>
            !line.toLowerCase().contains('headers:') &&
            !line.toLowerCase().contains('url:'),
        orElse: () => '',
      )
      .trim();
  if (cleanLine.isNotEmpty && cleanLine.length < 120) return cleanLine;
  return signingUp
      ? 'Sign up failed. Please check your details and try again.'
      : 'Request failed. Please check your details and try again.';
}
