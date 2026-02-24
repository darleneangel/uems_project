import 'dart:math';
import 'email_service.dart';

/// Authentication Service
/// Handles user authentication, password recovery, and OTP management
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final EmailService _emailService = EmailService();
  
  // Store OTPs temporarily (In production, use a secure backend)
  final Map<String, OTPData> _otpStorage = {};
  
  // Mock user database (In production, use real database)
  final Map<String, UserData> _userDatabase = {
    '123': UserData(
      userId: '123',
      email: 'student@uems.edu',
      name: 'Student User',
      role: 'student',
    ),
    '456': UserData(
      userId: '456',
      email: 'admin@uems.edu',
      name: 'Admin User',
      role: 'admin',
    ),
    '789': UserData(
      userId: '789',
      email: 'teacher@uems.edu',
      name: 'Teacher User',
      role: 'teacher',
    ),
  };

  /// Generate a 6-digit OTP
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  /// Send OTP to user's email for password recovery
  Future<Map<String, dynamic>> requestPasswordReset(String userId) async {
    try {
      // Check if user exists
      final user = _userDatabase[userId];
      if (user == null) {
        return {
          'success': false,
          'message': 'User ID not found',
        };
      }

      // Generate OTP
      final otp = _generateOTP();
      final expiryTime = DateTime.now().add(const Duration(minutes: 5));

      // Store OTP
      _otpStorage[userId] = OTPData(
        otp: otp,
        expiryTime: expiryTime,
        email: user.email,
      );

      // Send email
      final emailSent = await _emailService.sendOTPEmail(
        recipientEmail: user.email,
        recipientName: user.name,
        otp: otp,
      );

      if (emailSent) {
        return {
          'success': true,
          'message': 'OTP sent to ${_maskEmail(user.email)}',
          'email': _maskEmail(user.email),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send email. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Verify OTP entered by user
  Future<Map<String, dynamic>> verifyOTP(String userId, String enteredOTP) async {
    try {
      final otpData = _otpStorage[userId];
      
      if (otpData == null) {
        return {
          'success': false,
          'message': 'No OTP request found. Please request a new OTP.',
        };
      }

      // Check if OTP expired
      if (DateTime.now().isAfter(otpData.expiryTime)) {
        _otpStorage.remove(userId);
        return {
          'success': false,
          'message': 'OTP has expired. Please request a new one.',
        };
      }

      // Verify OTP
      if (otpData.otp == enteredOTP) {
        // Mark as verified but don't remove yet (needed for password reset)
        otpData.verified = true;
        return {
          'success': true,
          'message': 'OTP verified successfully',
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid OTP. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Reset password after successful OTP verification
  Future<Map<String, dynamic>> resetPassword(
    String userId,
    String newPassword,
  ) async {
    try {
      final otpData = _otpStorage[userId];
      
      if (otpData == null || !otpData.verified) {
        return {
          'success': false,
          'message': 'Please verify OTP first',
        };
      }

      // In production, hash password and update in database
      // For now, just simulate success
      
      // Clear OTP data
      _otpStorage.remove(userId);

      return {
        'success': true,
        'message': 'Password reset successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to reset password: ${e.toString()}',
      };
    }
  }

  /// Resend OTP
  Future<Map<String, dynamic>> resendOTP(String userId) async {
    // Remove existing OTP and generate new one
    _otpStorage.remove(userId);
    return await requestPasswordReset(userId);
  }

  /// Mask email for privacy (show only first 2 chars and domain)
  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }
    
    return '${username.substring(0, 2)}***@$domain';
  }
}

/// OTP Data Model
class OTPData {
  final String otp;
  final DateTime expiryTime;
  final String email;
  bool verified;

  OTPData({
    required this.otp,
    required this.expiryTime,
    required this.email,
    this.verified = false,
  });
}

/// User Data Model
class UserData {
  final String userId;
  final String email;
  final String name;
  final String role;

  UserData({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
  });
}
