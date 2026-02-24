import 'dart:async';

/// Email Service
/// Handles sending emails for OTP and notifications
/// Note: This is a mock implementation. In production, use a real email service
/// like SendGrid, AWS SES, Firebase Cloud Functions, or your backend API
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  /// Send OTP email to user
  /// In production, this would connect to your email service provider
  Future<bool> sendOTPEmail({
    required String recipientEmail,
    required String recipientName,
    required String otp,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // In production, integrate with email service:
      // 
      // Example with HTTP request to backend:
      // final response = await http.post(
      //   Uri.parse('https://your-backend.com/api/send-otp'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'email': recipientEmail,
      //     'name': recipientName,
      //     'otp': otp,
      //   }),
      // );
      // return response.statusCode == 200;

      // For development/demo, log the email details
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📧 EMAIL SENT (SIMULATED)');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('To: $recipientEmail');
      print('Subject: Your UEMS Password Reset OTP');
      print('');
      print('Hi $recipientName,');
      print('');
      print('Your OTP for password reset is:');
      print('');
      print('    ╔════════════════╗');
      print('    ║   $otp   ║');
      print('    ╚════════════════╝');
      print('');
      print('This OTP will expire in 5 minutes.');
      print('');
      print('If you did not request this, please ignore this email.');
      print('');
      print('Best regards,');
      print('UEMS Team');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return true; // Simulate success
    } catch (e) {
      print('Failed to send email: $e');
      return false;
    }
  }

  /// Send password change confirmation email
  Future<bool> sendPasswordChangedEmail({
    required String recipientEmail,
    required String recipientName,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📧 EMAIL SENT (SIMULATED)');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('To: $recipientEmail');
      print('Subject: Your UEMS Password Has Been Changed');
      print('');
      print('Hi $recipientName,');
      print('');
      print('This is to confirm that your password has been successfully changed.');
      print('');
      print('If you did not make this change, please contact support immediately.');
      print('');
      print('Best regards,');
      print('UEMS Team');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return true;
    } catch (e) {
      print('Failed to send email: $e');
      return false;
    }
  }
}
