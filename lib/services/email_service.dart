import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Email Service
/// Handles sending real SMTP emails via your Supabase Edge Function for OTPs.
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // Your actual deployed Supabase Edge Function URL:
  final String _functionUrl =
      'https://ipmkemontxkxzfymidej.supabase.co/functions/v1/send-otp';

  /// Sends a secure OTP email via your deployed Supabase Edge Function.
  Future<bool> sendOTPEmail({
    required String recipientEmail,
    required String recipientName,
    required String otp,
  }) async {
    try {
      print(
          '📧 UEMSSP Core: Attempting to dispatch security payload to $_functionUrl...');

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'toEmail': recipientEmail,
          'otp': otp,
          'name': recipientName,
        }),
      );

      if (response.statusCode == 200) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('📧 EMAIL DISPATCHED LIVE');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('To: $recipientEmail');
        print('Code: $otp');
        print('Status: Successfully routed through Supabase SMTP Core.');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return true;
      } else {
        print('❌ SMTP Error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Failed to connect to Edge Function: $e');
      return false;
    }
  }

  /// Sends a password change confirmation email.
  Future<bool> sendPasswordChangedEmail({
    required String recipientEmail,
    required String recipientName,
  }) async {
    try {
      print(
          '📧 UEMSSP Core: Requesting password change confirmation dispatch...');

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'toEmail': recipientEmail,
          'otp':
              'PASSWORD_CHANGED', // Let the function know this is a confirmation notification
          'name': recipientName,
        }),
      );

      if (response.statusCode == 200) {
        print(
            '📧 Security update confirmation dispatched successfully to $recipientEmail.');
        return true;
      } else {
        print('❌ SMTP Error (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Failed to connect to Edge Function: $e');
      return false;
    }
  }
}
