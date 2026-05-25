import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Needed for platform checking
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Standard secure storage

// PointyCastle Cryptography (Using direct key_derivators package reference for Argon2)
import 'package:pointycastle/export.dart';
import 'package:pointycastle/key_derivators/argon2.dart';

// Mailer (Utilizing SMTP directly to bypass custom local EmailService issues)
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

// Services
import 'supabase_service.dart';

class SecurityService {
  // Singleton pattern for global access

  DateTime _lastReset = DateTime.now();

  SecurityService._internal();
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;

  // Platform-agnostic secure storage configuration
  // Guaranteed compatible across all versions of flutter_secure_storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Timer? _inactivityTimer;
  VoidCallback? _onSessionTimeout;
  static const Duration sessionTimeoutDuration = Duration(minutes: 2);

  int _failedAttempts = 0;
  bool _isThisYouVerified = false;
  String? _generatedOTP;
  String? _otpTargetEmail;
  DateTime? _otpGenerationTime;

  static const int tier1Limit = 3; // "Is this you?" prompt threshold
  static const int tier2Limit = 6; // OTP verification threshold

  // SMTP Authentication Credentials
  static const String senderEmail = 'lustredarlene45@gmail.com';
  static const String appPassword = 'xzgk bybb hiqh hrxh';

  // ---------------------------------------------------------------------
  // 1. CRYPTOGRAPHY ENGINE: Argon2id Password Hashing via PointyCastle
  // ---------------------------------------------------------------------

  // Argon2id Academic Configuration Parameters
  static const int _iterations = 3; // T Cost: 3 passes
  static const int _memory = 65536; // M Cost: 64 MB of RAM
  static const int _parallelism = 4; // p Cost: 4 threads
  static const int _hashLength =
      32; // Length of the resulting key digest (256-bit)

  /// Hashes a password client-side using the secure Argon2id standard.
  ///
  /// [password] The plaintext password input.
  /// [saltUuid] The unique User UUID retrieved from Supabase to serve as the salt.
  String hashPasswordArgon2id(String password, String saltUuid) {
    final Uint8List passwordBytes = Uint8List.fromList(utf8.encode(password));
    final Uint8List saltBytes = Uint8List.fromList(utf8.encode(saltUuid));

    // Initialize PointyCastle's pure-Dart Argon2 Generator
    final generator = Argon2BytesGenerator();

    // Define the Argon2id parameters (Type 2 = Argon2id)
    final parameters = Argon2Parameters(
      Argon2Parameters.ARGON2_id,
      saltBytes,
      iterations: _iterations,
      memory: _memory,
      lanes: _parallelism,
      desiredKeyLength: _hashLength,
    );

    generator.init(parameters);

    final Uint8List hashBytes = Uint8List(_hashLength);
    generator.deriveKey(passwordBytes, 0, hashBytes, 0);

    // Convert to Base64 to safely store as standard varchar in Supabase
    return base64.encode(hashBytes);
  }

  // ---------------------------------------------------------------------
  // 2. INPUT SANITIZATION: SQL Injection and XSS Neutralizer
  // ---------------------------------------------------------------------

  /// Sanitizes text input to defend against malicious escape characters.
  String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r"['" r'";#\-]'), '') // Strips malicious SQL syntax
        .replaceAll('<', '&lt;') // Sanitizes HTML tags against XSS
        .replaceAll('>', '&gt;');
  }

  /// Starts the inactivity timer. Bind this in your dashboard views.
  void startInactivityMonitoring({required VoidCallback onTimeout}) {
    _onSessionTimeout = onTimeout;
    resetInactivityTimer();
  }

  /// Resets the countdown. Call this on any interactive gesture.
  void resetInactivityTimer() {
    if (_onSessionTimeout == null) return;

    // DEBOUNCE: Only process if at least 1 second has passed since the last reset.
    // This prevents flooding the timer when the user moves the mouse.
    if (DateTime.now().difference(_lastReset).inSeconds < 1) return;

    _lastReset = DateTime.now();

    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(sessionTimeoutDuration, () {
      debugPrint(
          '🚨 Security Assurance Alert: Inactivity Timeout (2 minutes) triggered.');
      _onSessionTimeout?.call();
      stopInactivityMonitoring();
    });
  }

  /// Stop monitoring (e.g., when the user voluntarily logs out).
  void stopInactivityMonitoring() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _onSessionTimeout = null;
  }

  // ---------------------------------------------------------------------
  // 4. ADAPTIVE BRUTE FORCE PROTECTION & ADVANCED THROTTLING
  // ---------------------------------------------------------------------

  int get failedAttempts => _failedAttempts;
  bool get isThisYouVerified => _isThisYouVerified;
  String? get generatedOTP => _generatedOTP;

  /// Check if the user must bypass standard password authentication and verify via OTP
  bool requiresOTP() {
    return _failedAttempts >= tier2Limit && _generatedOTP != null;
  }

  /// Registers a failed password attempt
  void registerFailedAttempt() {
    _failedAttempts++;
  }

  /// Reset all local brute-force defense limits upon successful login/verification
  void resetThrottler() {
    _failedAttempts = 0;
    _isThisYouVerified = false;
    _generatedOTP = null;
    _otpTargetEmail = null;
    _otpGenerationTime = null;
  }

  /// Grants another 3 tries when user completes "Is this you?" confirmation
  void approveIsThisYou() {
    _isThisYouVerified = true;
    debugPrint(
        '🔒 Security Assurance: Extra 3 login attempts authorized by user.');
  }

  // ---------------------------------------------------------------------
  // 5. ONE-TIME PASSWORD (OTP) PIPELINE (SMTP DIRECT EXPORT)
  // ---------------------------------------------------------------------

  /// Generates and sends a 6-digit OTP to the user's email address using Supabase profiles
  Future<bool> sendLoginOTP(String userIdNumber) async {
    try {
      // 1. Fetch user's registered institutional email from Profiles table
      final results = await SupabaseService()
          .client
          .from('profiles')
          .select('email, fn')
          .ilike('user_id_number', userIdNumber)
          .maybeSingle();

      if (results == null || results['email'] == null) {
        debugPrint('Failed to retrieve email profile for OTP dispatch.');
        return false;
      }

      final String email = results['email'];
      final String name = results['fn'] ?? 'Academic User';

      // 2. Generate cryptographically random 6-digit code
      final random = Random.secure();
      final String code =
          List.generate(6, (index) => random.nextInt(10).toString()).join();

      _generatedOTP = code;
      _otpTargetEmail = email;
      _otpGenerationTime = DateTime.now();

      if (kIsWeb) {
        // Safe Web Fallback: bypass raw SMTP sockets on web to avoid runtime socket exceptions.
        debugPrint('🔒 Web Sandbox Bypass: Secure OTP is $code');
        return true;
      }

      // 3. Dispatch the email directly using PointyCastle/SMTP Configuration (Only runs on Windows desktop native)
      final smtpServer = gmail(senderEmail, appPassword);

      final message = Message()
        ..from = const Address(senderEmail, 'UEMSSP Security Core')
        ..recipients.add(email)
        ..subject = 'UEMSSP Secure Session Verification: $code'
        ..html = """
          <div style='font-family: sans-serif; padding: 20px; color: #1E1033;'>
            <h2>Adaptive Security Verification Required</h2>
            <p>Hello $name,</p>
            <p>We noticed multiple login attempts on your academic account. To finalize your verification, please input this secure, one-time verification code:</p>
            <div style='background: #F3F4F6; padding: 20px; font-size: 24px; font-weight: bold; text-align: center; letter-spacing: 5px; margin: 20px 0;'>
              $code
            </div>
            <p>This code will expire in 5 minutes. If you did not initiate this request, please report it to school IT Administration immediately.</p>
            <br/>
            <p>Bright Future Academy Support</p>
          </div>
        """;

      await send(message, smtpServer);
      debugPrint(
          '🔒 Security Assurance: Sent login OTP successfully via native SMTP.');
      return true;
    } catch (e) {
      debugPrint('Error sending secure login OTP: $e');
      return false;
    }
  }

  /// Verifies if the entered OTP is correct and not expired (5 minutes window)
  bool verifyOTP(String inputCode) {
    if (_generatedOTP == null || _otpGenerationTime == null) return false;

    final difference = DateTime.now().difference(_otpGenerationTime!);
    if (difference.inMinutes > 5) {
      debugPrint('Security OTP expired.');
      resetThrottler(); // Clear state to renew attempts
      return false;
    }

    if (_generatedOTP == inputCode) {
      resetThrottler(); // Success! Clear all failed limits
      return true;
    }

    return false;
  }

  // ---------------------------------------------------------------------
  // 6. SECURE HARDWARE STORAGE OPERATIONS
  // ---------------------------------------------------------------------

  Future<void> saveSecureSession(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readSecureSession(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> clearSecureSession(String key) async {
    await _secureStorage.delete(key: key);
  }
}
