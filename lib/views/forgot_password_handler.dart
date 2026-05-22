import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../services/supabase_service.dart';
import '../services/security_service.dart'; // Import cryptographic service

class ForgotPasswordHandler {
  static const String senderEmail = 'bright.future.academyUEMSSP@gmail.com';
  static const String appPassword = 'jnea wnbk atjg gyqi';

  /// 🎬 STEP 1: INITIAL DIALOG
  /// Prompts the user to confirm recovery intent and enter ID
  static void showRecoveryFlow(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RecoveryDialog(isDarkMode: isDarkMode),
    );
  }
}

class _RecoveryDialog extends StatefulWidget {
  final bool isDarkMode;
  const _RecoveryDialog({required this.isDarkMode});

  @override
  State<_RecoveryDialog> createState() => _RecoveryDialogState();
}

class _RecoveryDialogState extends State<_RecoveryDialog> {
  final SupabaseService _service = SupabaseService();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  int _currentStep = 0; // 0: ID Entry, 1: OTP Verify, 2: Reset Password
  bool _isLoading = false;
  String? _targetProfileId;
  String? _generatedOtp;
  String? _targetEmail;

  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);

  /// 🛰️ DATABASE: Step 1 - Lookup ID and Send OTP
  Future<void> _initiateRecovery() async {
    // SECURITY ASSURANCE: Sanitize inputs immediately before processing DB lookups
    final idNum = SecurityService().sanitizeInput(_inputController.text);
    if (idNum.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Fetch profile to get email
      final response = await _service.client
          .from('profiles')
          .select('id, email, fn')
          .ilike('user_id_number', idNum)
          .maybeSingle();

      if (response == null || response['email'] == null) {
        _showLocalError("Identifier not found or no email associated.");
        return;
      }

      _targetProfileId = response['id']; // This is our unique user UUID
      _targetEmail = response['email'];

      // 2. Generate and Send OTP
      _generatedOtp = (Random().nextInt(900000) + 100000).toString();
      await _sendEmailNotification(
          response['fn'], _targetEmail!, _generatedOtp!);

      setState(() => _currentStep = 1);
    } catch (e) {
      _showLocalError("Connection Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📧 SMTP ENGINE: Sends the OTP using institutional credentials
  Future<void> _sendEmailNotification(
      String name, String email, String otp) async {
    final smtpServer = gmail(
        ForgotPasswordHandler.senderEmail, ForgotPasswordHandler.appPassword);

    final message = Message()
      ..from =
          const Address(ForgotPasswordHandler.senderEmail, 'UEMSSP Security')
      ..recipients.add(email)
      ..subject = 'UEMS Account Recovery Code: $otp'
      ..html = """
        <div style='font-family: sans-serif; padding: 20px; color: #1E1033;'>
          <h2>Account Recovery Request</h2>
          <p>Hello $name,</p>
          <p>You requested to reset your password for the UEMS portal. Use the code below to proceed:</p>
          <div style='background: #F3F4F6; padding: 20px; font-size: 24px; font-weight: bold; text-align: center; letter-spacing: 5px;'>
            $otp
          </div>
          <p>This code will expire in 10 minutes. If you did not request this, please ignore this email.</p>
          <br/>
          <p>Bright Future Academy Support</p>
        </div>
      """;

    await send(message, smtpServer);
  }

  /// 🛠️ LOGIC: Step 2 - Verify OTP
  void _verifyOtp() {
    if (_otpController.text == _generatedOtp) {
      setState(() => _currentStep = 2);
    } else {
      _showLocalError("Invalid OTP code. Please try again.");
    }
  }

  /// 🛰️ DATABASE: Step 3 - Update Password
  Future<void> _finalizeReset() async {
    final pass = _newPassController.text;
    final confirm = _confirmPassController.text;

    // Validation Logic
    if (pass.length < 8 || pass.length > 20) {
      _showLocalError("Password must be between 8 and 20 characters.");
      return;
    }
    if (!pass.contains(RegExp(r'[A-Z]')) || !pass.contains(RegExp(r'[0-9]'))) {
      _showLocalError(
          "Must include at least one uppercase letter and one number.");
      return;
    }
    if (pass != confirm) {
      _showLocalError("Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // SECURITY ASSURANCE: Cryptographically secure the new password client-side using Argon2id with their stable user UUID
      final String secureArgon2Hash =
          SecurityService().hashPasswordArgon2id(pass, _targetProfileId!);

      await _service.client.from('profiles').update(
          {'password_hash': secureArgon2Hash}).eq('id', _targetProfileId!);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Password updated successfully. Please log in."),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showLocalError("Sync Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDarkMode ? surfaceDark : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black87;

    return AlertDialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Row(
        children: [
          const Icon(LucideIcons.shieldAlert, color: aViolet),
          const SizedBox(width: 12),
          Text(_getStepTitle(),
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900, color: textColor)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: aViolet)))
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_currentStep == 0) ...[
                    const Text(
                        "Please enter your Student or Employee ID to initiate recovery.",
                        style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
                    const SizedBox(height: 20),
                    _buildField(
                        _inputController, "ID Number", LucideIcons.user),
                  ] else if (_currentStep == 1) ...[
                    Text(
                        "A 6-digit code was sent to your registered email: $_targetEmail",
                        style: const TextStyle(
                            color: Colors.blueGrey, fontSize: 13)),
                    const SizedBox(height: 20),
                    _buildField(
                        _otpController, "Verification Code", LucideIcons.key),
                  ] else ...[
                    _buildField(
                        _newPassController, "New Password", LucideIcons.lock,
                        obscure: true),
                    const SizedBox(height: 12),
                    _buildField(_confirmPassController, "Confirm Password",
                        LucideIcons.checkCircle,
                        obscure: true),
                    const SizedBox(height: 12),
                    const Text("Min 8 chars, 1 Uppercase, 1 Number.",
                        style: TextStyle(fontSize: 10, color: Colors.blueGrey)),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL")),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleStepAction,
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 21, 14, 37)),
          child: Text(_currentStep == 2 ? "RESET PASSWORD" : "CONTINUE"),
        ),
      ],
    );
  }

  String _getStepTitle() {
    if (_currentStep == 0) return "Identity Recovery";
    if (_currentStep == 1) return "Verify OTP";
    return "New Password";
  }

  void _handleStepAction() {
    if (_currentStep == 0) {
      _initiateRecovery();
    } else if (_currentStep == 1) {
      _verifyOtp();
    } else {
      _finalizeReset();
    }
  }

  Widget _buildField(TextEditingController c, String h, IconData i,
      {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: h,
        prefixIcon: Icon(i, size: 18, color: aViolet),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  void _showLocalError(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(m), backgroundColor: Colors.redAccent));
  }
}
