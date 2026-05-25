import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';

// Core Services
import '../services/supabase_service.dart';

// Import platform-aware redirect helper & security systems
import '../services/navigation_helper.dart';
import '../services/security_service.dart';
import 'forgot_password_handler.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TOP-LEVEL ISOLATE FUNCTION — must be outside the class for compute() to work
// Runs Argon2id hashing in a separate web worker on WASM / background isolate
// on native, completely freeing the main UI thread.
// ─────────────────────────────────────────────────────────────────────────────
Future<String> _computeArgon2Hash(List<String> args) async {
  // args[0] = raw password, args[1] = user UUID salt
  return SecurityService().hashPasswordArgon2id(args[0], args[1]);
}

class UEMSLoginPage extends StatefulWidget {
  const UEMSLoginPage({super.key});

  @override
  State<UEMSLoginPage> createState() => _UEMSLoginPageState();
}

class _UEMSLoginPageState extends State<UEMSLoginPage>
    with TickerProviderStateMixin {
  String _currentView =
      'login'; // 'login', 'first_login_reset', 'welcome_uemssp'
  bool _isDarkMode = true;

  // WASM OPTIMIZATION: ValueNotifier isolates loading repaints to the button only.
  // Previously, setState(() => _isLoading = true) was repainting the entire tree
  // including the left gradient panel — causing cascading layout recalculations.
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(false);

  bool _isEntranceAnimationComplete =
      false; // PERFORMANCE OPTIMIZATION: Track completion state

  // Login Password Obscure Trigger
  bool _isPasswordVisible = false;

  // First-Time Reset Password Obscure Triggers
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Map<String, dynamic>? _loggedInUserData;

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // First-Time Reset Controllers
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late AnimationController _formController;
  late AnimationController _welcomeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _welcomeOpacity;
  late List<Animation<double>> _formElementAnimations;

  static const Color pViolet = Color(0xFF1E1033);
  static const Color sViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);
  static const Color tDark = Color(0xFF0F071D);
  static const Color success = Color(0xFF69F0AE);
  static const Color warning = Color(0xFFFFD740);
  static const Color error = Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    _formController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _formElementAnimations = List.generate(7, (i) {
      return CurvedAnimation(
        parent: _formController,
        curve: Interval(0.1 + (i * 0.1), 1.0, curve: Curves.easeOutQuart),
      );
    });

    _welcomeController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
        CurvedAnimation(
            parent: _welcomeController, curve: Curves.easeInOutSine));
    _welcomeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _welcomeController, curve: const Interval(0.0, 0.4)));

    // PERFORMANCE OPTIMIZATION: Turn off animation listening tree after initial load finishes
    _formController.forward().then((_) {
      if (mounted) {
        setState(() {
          _isEntranceAnimationComplete = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _formController.dispose();
    _welcomeController.dispose();
    _loadingNotifier.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 📐 Password Strength Assessment Algorithm
  Map<String, dynamic> _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      return {"score": 0.0, "label": "EMPTY", "color": Colors.blueGrey};
    }

    double score = 0.1;
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    // Length metrics
    if (password.length >= 8) score += 0.3;
    if (password.length >= 12) score += 0.2;

    // Complexity metrics
    if (hasUpper && hasLower) score += 0.15;
    if (hasDigits) score += 0.15;
    if (hasSpecial) score += 0.1;

    score = score.clamp(0.0, 1.0);

    String label = "WEAK";
    Color color = error;

    if (score > 0.4 && score <= 0.75) {
      label = "GOOD";
      color = warning;
    } else if (score > 0.75) {
      label = "STRONG";
      color = success;
    }

    return {
      "score": score,
      "label": label,
      "color": color,
    };
  }

  TextStyle _getInterStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    if (kIsWeb) {
      return TextStyle(
        fontFamily:
            '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // OPTIMIZED _handleLogin
  // Key changes vs original:
  //   1. Removed 150ms artificial delay on web (kIsWeb guard)
  //   2. hashPasswordArgon2id() now runs via compute() → web worker on WASM,
  //      background isolate on native. This was the source of the 14,592ms INP.
  //   3. Password hash migration write is fire-and-forget (no await blocking login)
  //   4. recordAttendanceLogin is fire-and-forget (no await before routing)
  //   5. _loadingNotifier.value replaces setState for loading state so only the
  //      button widget repaints instead of the entire Scaffold tree
  // ─────────────────────────────────────────────────────────────────────────
  void _handleLogin() async {
    final security = SecurityService();

    final id = security.sanitizeInput(_idController.text);
    final pass = _passwordController.text.trim();

    if (id.isEmpty || pass.isEmpty) {
      _showError("Identity Credentials Required");
      return;
    }

    if (security.requiresOTP()) {
      _showOTPDialog(id);
      return;
    }

    // WASM OPTIMIZATION: ValueNotifier update — only the button repaints
    _loadingNotifier.value = true;

    // WASM OPTIMIZATION: Skip artificial delay on web — microtask flush is sufficient
    if (!kIsWeb) await Future.delayed(const Duration(milliseconds: 150));

    try {
      final service = SupabaseService();

      final results = await service.client
          .from('profiles')
          .select('*, student_details(*), employee_details(*)')
          .ilike('user_id_number', id);

      if (!mounted) return;

      if (results.isNotEmpty) {
        final userData = results.first;
        final String storedHash = userData['password_hash'] ?? '';
        final String userUuid = userData['id'] ?? '';

        bool isAuthenticated = false;

        bool isAlreadyHashed(String value) {
          return value.length >= 24 && !value.contains(' ');
        }

        if (!isAlreadyHashed(storedHash) && storedHash == pass) {
          debugPrint('⚡ Plaintext password migration match detected.');

          // WASM OPTIMIZATION: Hash runs off main thread, write is fire-and-forget
          compute(_computeArgon2Hash, [pass, userUuid]).then((hashed) {
            service.client
                .from('profiles')
                .update({'password_hash': hashed})
                .eq('id', userUuid)
                .then((_) => debugPrint('✅ Password hash migrated.'))
                .catchError((e) => debugPrint('⚠️ Hash migration failed: $e'));
          });

          isAuthenticated = true;
        } else {
          if (storedHash.isNotEmpty) {
            // WASM OPTIMIZATION: compute() moves Argon2 off the main thread.
            // Previously this ran synchronously, causing the 14,592ms INP spike.
            final String computedInputHash =
                await compute(_computeArgon2Hash, [pass, userUuid]);

            if (computedInputHash == storedHash) {
              isAuthenticated = true;
            } else if (storedHash.length < computedInputHash.length &&
                computedInputHash.startsWith(storedHash)) {
              isAuthenticated = true;
            }
          }
        }

        if (isAuthenticated) {
          security.resetThrottler();

          final String status = userData['account_status'] ?? 'Active';
          if (status != 'Active') {
            _loadingNotifier.value = false;
            _showSuspendedDialog(status);
            return;
          }

          // 🛡️ SECURITY INTERCEPTOR: Detect if they are using their temporary credentials
          final String cleanFn =
              userData['fn'].toString().toLowerCase().replaceAll(' ', '');
          final String studentIdNum = userData['user_id_number'].toString();
          final String defaultPassword = "$cleanFn$studentIdNum";

          if (pass == defaultPassword) {
            debugPrint(
                "🚨 Security Intercept: Force temporary credentials update.");
            _loadingNotifier.value = false;
            setState(() {
              _loggedInUserData = userData;
              _currentView = 'first_login_reset';
            });
            return;
          }

          _loggedInUserData = userData;
          final String role =
              (_loggedInUserData!['role'] as String).toLowerCase();

          // WASM OPTIMIZATION: Fire attendance log async — do not await before routing
          service
              .recordAttendanceLogin(_loggedInUserData!['id'], role)
              .catchError((e) => debugPrint('⚠️ Attendance log failed: $e'));

          _loadingNotifier.value = false;
          _routeToDashboard(role);
        } else {
          _processFailedAttempt(security, id);
        }
      } else {
        _processFailedAttempt(security, id);
      }
    } catch (e) {
      if (mounted) _loadingNotifier.value = false;
      _showError("Sync Error: Unable to reach academic core.");
    }
  }

  /// 🛰️ TRANSMISSION: Force write the updated secure password hash back to profiles
  Future<void> _handleFirstTimeReset() async {
    if (_loggedInUserData == null) return;

    final String newPass = _newPasswordController.text;
    final String confirmPass = _confirmPasswordController.text;

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showError("Please fill in both password fields.");
      return;
    }

    if (newPass != confirmPass) {
      _showError("Passwords do not match. Please verify.");
      return;
    }

    final strength = _checkPasswordStrength(newPass);
    if (strength['label'] == "WEAK") {
      _showError("For security, your password must not be rated WEAK.");
      return;
    }

    final String cleanFn =
        _loggedInUserData!['fn'].toString().toLowerCase().replaceAll(' ', '');
    final String studentIdNum = _loggedInUserData!['user_id_number'].toString();
    final String defaultPassword = "$cleanFn$studentIdNum";

    if (newPass == defaultPassword) {
      _showError(
          "Your new password cannot be the same as your temporary password.");
      return;
    }

    _loadingNotifier.value = true;
    await Future.delayed(const Duration(milliseconds: 150));

    try {
      final security = SecurityService();
      final String userUuid = _loggedInUserData!['id'] ?? '';

      // Hash new credential using Argon2id off the main thread
      final String newlyHashedPassword =
          await compute(_computeArgon2Hash, [newPass, userUuid]);

      // Save to database
      await SupabaseService()
          .client
          .from('profiles')
          .update({'password_hash': newlyHashedPassword}).eq('id', userUuid);

      _loadingNotifier.value = false;

      _showSuccessBanner(
          "Password updated successfully! Account is now activated.");

      // Proceed safely to dashboard routing
      final String role = (_loggedInUserData!['role'] as String).toLowerCase();
      _routeToDashboard(role);
    } catch (e) {
      _loadingNotifier.value = false;
      _showError("Database Upgrade Error: $e");
    }
  }

  void _processFailedAttempt(SecurityService security, String idNumber) async {
    _loadingNotifier.value = false;
    security.registerFailedAttempt();

    if (security.failedAttempts == 3 && !security.isThisYouVerified) {
      _showIsThisYouDialog();
    } else if (security.failedAttempts >= 6) {
      _loadingNotifier.value = true;
      final otpSent = await security.sendLoginOTP(idNumber);
      _loadingNotifier.value = false;

      if (otpSent) {
        _showOTPDialog(idNumber);
      } else {
        _showError(
            "Security Lockout: System verification core is currently unreachable.");
      }
    } else {
      _showError(
          "Identity Mismatch. Please check your credentials. (${security.failedAttempts}/6 attempts used)");
    }
  }

  void _showIsThisYouDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.gpp_maybe_rounded, color: Colors.amber),
            SizedBox(width: 12),
            Text("Is This You?",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Unusual login failure patterns detected. Confirm you are the legitimate account owner to request an additional 3 attempts.",
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              SecurityService().resetThrottler();
            },
            child: const Text("NO, LOCK ACCESS",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              SecurityService().approveIsThisYou();
              Navigator.pop(ctx);
              _showError("Verified! 3 additional login attempts authorized.");
            },
            child: const Text("YES, THAT'S ME",
                style: TextStyle(color: aViolet, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _showOTPDialog(String idNumber) {
    final TextEditingController otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.mail_outline_rounded, color: aViolet),
            SizedBox(width: 12),
            Text("Verify OTP to Unlock",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Too many login attempts. We have dispatched a secure 6-digit verification code to your registered academic email. Input the code to proceed:",
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "•••••",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (SecurityService().verifyOTP(otpController.text.trim())) {
                Navigator.pop(ctx);
                _showError(
                    "OTP Verified! Please enter correct credentials to sign in.");
              } else {
                _showError("Incorrect or expired OTP verification token.");
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: aViolet),
            child: const Text("VERIFY CODE"),
          )
        ],
      ),
    );
  }

  void _showSuspendedDialog(String status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.report_problem_rounded, color: Colors.redAccent),
            SizedBox(width: 12),
            Text("Access Restricted",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          "Your institutional account is currently $status. \n\n"
          "Portal access is prohibited under current status. Please coordinate with the Office of the Registrar or HR Management for verification.",
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("UNDERSTOOD",
                style: TextStyle(
                    color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _routeToDashboard(String role) {
    // WASM OPTIMIZATION: Skip the 3-second welcome animation entirely on web.
    // The welcome screen adds unnecessary paint cycles and timer overhead on WASM.
    // handleLoginRedirect already handles the desktop-only role gate internally.
    if (kIsWeb) {
      handleLoginRedirect(context, _loggedInUserData!);
      return;
    }

    setState(() => _currentView = 'welcome_uemssp');
    _welcomeController.repeat(reverse: true);

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _welcomeController.stop();
        handleLoginRedirect(context, _loggedInUserData!);
      }
    });
  }

  void _showError(String m) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16))),
      );

  void _showSuccessBanner(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(m,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black)),
            backgroundColor: success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(24),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16))),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: kIsWeb
          ? Duration.zero
          : const Duration(
              milliseconds:
                  600), // PERFORMANCE OPTIMIZATION: Instant view switching on web
      child: _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'login':
      case 'first_login_reset':
        return _buildSplitContainer();
      case 'welcome_uemssp':
        return _buildWelcomeLoading();
      default:
        return _buildSplitContainer();
    }
  }

  Widget _buildSplitContainer() {
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF1F5F9);
    final cardColor = _isDarkMode ? const Color(0xFF160D2B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 1200,
            constraints: const BoxConstraints(minHeight: 600, maxHeight: 850),
            clipBehavior: kIsWeb
                ? Clip.none
                : Clip
                    .antiAlias, // PERFORMANCE OPTIMIZATION: Bypassed heavy clip paths entirely on Web
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(56),
              border: kIsWeb
                  ? Border.all(
                      color: _isDarkMode ? Colors.white10 : Colors.black12,
                      width: 1.5)
                  : null,
              boxShadow: kIsWeb
                  ? []
                  : [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 80,
                          offset: const Offset(0, 40)),
                    ],
            ),
            child: Row(
              children: [
                // --- LEFT PANEL: THE STATIC BRANDING FRAME ---
                Expanded(
                  flex: 5,
                  child: RepaintBoundary(
                    child: Container(
                      padding: const EdgeInsets.all(60),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [pViolet, sViolet, aViolet],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          _MovingBackground(
                              isDarkMode: _isDarkMode,
                              isPaused: _loadingNotifier.value),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _animateEntrance(
                                  0,
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(24),
                                        border:
                                            Border.all(color: Colors.white24)),
                                    child: const Icon(Icons.school_rounded,
                                        color: Colors.white, size: 48),
                                  )),
                              const Spacer(),
                              _animateEntrance(
                                  1,
                                  Text(
                                    "BRIGHT.\nFUTURE.\nACADEMY.",
                                    style: GoogleFonts.inter(
                                        fontSize: 60,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        height: 0.95,
                                        letterSpacing: -3),
                                  )),
                              const SizedBox(height: 32),
                              _animateEntrance(
                                  2,
                                  Text(
                                    "UEMSSP: The Intelligent Core for Academic Excellence at Bright Future Academy.",
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w400,
                                        height: 1.5),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- RIGHT PANEL: THE DYNAMIC FORM CONTROLLER ---
                Expanded(
                  flex: 7,
                  child: RepaintBoundary(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 40),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _currentView == 'login'
                            ? _buildLoginForm()
                            : _buildFirstTimeResetForm(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    final textColor = _isDarkMode ? Colors.white : Colors.black;
    return StatefulBuilder(
        key: const ValueKey('login_form_builder'),
        builder: (context, setFormState) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _animateEntrance(
                        0,
                        const Icon(Icons.school_rounded,
                            color: aViolet, size: 40)),
                    _animateEntrance(0, _buildThemeToggle()),
                  ],
                ),
                const SizedBox(height: 40),
                _animateEntrance(
                    1,
                    Text("WELCOME BACK",
                        style: _getInterStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: -2))),
                _animateEntrance(
                    1,
                    Text("Initialize your secure institutional session.",
                        style: TextStyle(
                            color: Colors.blueGrey.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w500))),
                const SizedBox(height: 40),
                _animateEntrance(2, _buildLabel("Identification Number")),
                _animateEntrance(
                    2,
                    _buildTextField(
                        _idController, "e.g., 202350031", Icons.badge_rounded,
                        onSubmitted: (_) => _handleLogin())),
                const SizedBox(height: 24),
                _animateEntrance(3, _buildLabel("Password")),
                _animateEntrance(
                    3,
                    _buildTextField(
                      _passwordController,
                      "••••••••",
                      Icons.lock_rounded,
                      obscure: !_isPasswordVisible,
                      onSubmitted: (_) => _handleLogin(),
                      suffix: IconButton(
                        icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: aViolet,
                            size: 20),
                        onPressed: () => setFormState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    )),
                const SizedBox(height: 24),
                _animateEntrance(
                    4,
                    Row(
                      children: [
                        const Spacer(),
                        TextButton(
                            onPressed: () =>
                                ForgotPasswordHandler.showRecoveryFlow(
                                    context, _isDarkMode),
                            child: const Text("Forgot Password?",
                                style: TextStyle(
                                    color: aViolet,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold))),
                      ],
                    )),
                const SizedBox(height: 40),

                // ── LOGIN BUTTON ──────────────────────────────────────────
                // WASM OPTIMIZATION: ValueListenableBuilder scopes repaints to
                // this button only. Previously the entire Scaffold repainted on
                // every _isLoading toggle, including the left gradient panel.
                _animateEntrance(
                    5,
                    ValueListenableBuilder<bool>(
                      valueListenable: _loadingNotifier,
                      builder: (context, isLoading, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 65,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isLoading
                                  ? aViolet.withOpacity(0.7)
                                  : aViolet,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5)),
                                      SizedBox(width: 12),
                                      Text("SECURING SESSION...",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                              fontSize: 14))
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("LOG IN",
                                          style: TextStyle(
                                              fontFamily:
                                                  kIsWeb ? 'System-UI' : null,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.5,
                                              fontSize: 14)),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.arrow_forward_rounded,
                                          size: 20),
                                    ],
                                  ),
                          ),
                        );
                      },
                    )),

                const SizedBox(height: 40),
                _animateEntrance(
                    6,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("VISION",
                            style: _getInterStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: _isDarkMode
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.black,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Text(
                            "Bright Future Academy envisions becoming a center of excellence in education that nurtures knowledgeable, skilled, and values-driven individuals who contribute positively to society.",
                            style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.black.withOpacity(0.6),
                                fontSize: 11,
                                height: 1.4)),
                        const SizedBox(height: 16),
                        Text("MISSION",
                            style: _getInterStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: _isDarkMode
                                    ? Colors.white.withOpacity(0.6)
                                    : Colors.black,
                                letterSpacing: 1.5)),
                        const SizedBox(height: 6),
                        Text(
                            "Bright Future Academy is committed to: Providing quality and accessible education to all learners. Developing students' academic competence, creativity, and critical thinking skills. Promoting discipline, respect, and integrity within the school community. Preparing students for higher education, employment, and responsible citizenship. Creating a safe and supportive learning environment.",
                            style: TextStyle(
                                color: _isDarkMode
                                    ? Colors.white.withOpacity(0.5)
                                    : Colors.black.withOpacity(0.6),
                                fontSize: 11,
                                height: 1.4)),
                      ],
                    )),
              ],
            ),
          );
        });
  }

  /// 🛡️ FIRST LOGIN RESET CREDENTIALS INTERCEPTOR VIEW
  Widget _buildFirstTimeResetForm() {
    final textColor = _isDarkMode ? Colors.white : Colors.black;

    return StatefulBuilder(
        key: const ValueKey('reset_form_builder'),
        builder: (context, setFormState) {
          final strength = _checkPasswordStrength(_newPasswordController.text);
          return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.security_rounded,
                          color: warning, size: 40),
                      _buildThemeToggle(),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text("ACTIVATE YOUR PORTAL",
                      style: _getInterStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -1.5)),
                  const SizedBox(height: 4),
                  Text(
                      "For your security, you must replace your registrar-issued temporary password before you can proceed.",
                      style: TextStyle(
                          color: Colors.blueGrey.withOpacity(0.9),
                          fontSize: 14,
                          height: 1.4)),
                  const SizedBox(height: 32),
                  _buildLabel("Create New Password"),
                  _buildTextField(
                    _newPasswordController,
                    "Enter strong password",
                    Icons.vpn_key_rounded,
                    obscure: !_isNewPasswordVisible,
                    onChanged: (_) => setFormState(() {}),
                    suffix: IconButton(
                      icon: Icon(
                          _isNewPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: aViolet,
                          size: 20),
                      onPressed: () => setFormState(
                          () => _isNewPasswordVisible = !_isNewPasswordVisible),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password Strength Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("PASSWORD COMPLEXITY:",
                          style: TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                      Text(
                        strength['label'],
                        style: TextStyle(
                            color: strength['color'],
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: strength['score'],
                      color: strength['color'],
                      backgroundColor:
                          _isDarkMode ? Colors.white10 : Colors.black12,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildLabel("Confirm New Password"),
                  _buildTextField(
                    _confirmPasswordController,
                    "Re-type password to verify",
                    Icons.lock_reset_rounded,
                    obscure: !_isConfirmPasswordVisible,
                    onChanged: (_) => setFormState(() {}),
                    suffix: IconButton(
                      icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                          color: aViolet,
                          size: 20),
                      onPressed: () => setFormState(() =>
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── ACTIVATE BUTTON ───────────────────────────────────
                  ValueListenableBuilder<bool>(
                    valueListenable: _loadingNotifier,
                    builder: (context, isLoading, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 65,
                        child: ElevatedButton.icon(
                          onPressed: isLoading ? null : _handleFirstTimeReset,
                          icon: const Icon(Icons.check_circle_outline_rounded,
                              size: 20),
                          label: Text("ACTIVATE ACCOUNT & LOG IN",
                              style: TextStyle(
                                  fontFamily: kIsWeb ? 'System-UI' : null,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  fontSize: 14)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: success,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                            elevation: 0,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("VISION",
                          style: _getInterStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _isDarkMode
                                  ? Colors.white.withOpacity(0.6)
                                  : Colors.black,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 6),
                      Text(
                          "Bright Future Academy envisions becoming a center of excellence in education that nurtures knowledgeable, skilled, and values-driven individuals who contribute positively to society.",
                          style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.6),
                              fontSize: 11,
                              height: 1.4)),
                      const SizedBox(height: 16),
                      Text("MISSION",
                          style: _getInterStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _isDarkMode
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 6),
                      Text(
                          "Bright Future Academy is committed to: Providing quality and accessible education to all learners. Developing students' academic competence, creativity, and critical thinking skills. Promoting discipline, respect, and integrity within the school community. Preparing students for higher education, employment, and responsible citizenship. Creating a safe and supportive learning environment.",
                          style: TextStyle(
                              color: _isDarkMode
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.6),
                              fontSize: 11,
                              height: 1.4)),
                    ],
                  ),
                ],
              ));
        });
  }

  Widget _buildWelcomeLoading() {
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF1F5F9);
    final textColor = _isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: FadeTransition(
          opacity: _welcomeOpacity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: kIsWeb
                        ? []
                        : [
                            BoxShadow(
                                color: aViolet.withOpacity(0.35),
                                blurRadius: 40,
                                spreadRadius: 2),
                          ],
                    gradient: const RadialGradient(
                      colors: [aViolet, sViolet, pViolet],
                      stops: [0.3, 0.7, 1.0],
                    ),
                  ),
                  child: const ClipOval(
                    child: Icon(Icons.verified_user_rounded,
                        color: Colors.white, size: 80),
                  ),
                ),
              ),
              const SizedBox(height: 80),
              Text("Welcome to UEMSSP",
                  style: GoogleFonts.inter(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                      letterSpacing: -2)),
              const SizedBox(height: 16),
              Text(
                  "VERIFIED: Access granted to ${_loggedInUserData?['fn'] ?? 'Academic Node'}",
                  style: const TextStyle(
                      color: success,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3)),
              const SizedBox(height: 70),
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        color: aViolet,
                        backgroundColor: _isDarkMode
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.05),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text("Synchronizing encrypted academic pipeline...",
                        style: TextStyle(
                            color: _isDarkMode
                                ? Colors.blueGrey
                                : pViolet.withOpacity(0.6),
                            fontSize: 13,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _animateEntrance(int index, Widget child) {
    if (_isEntranceAnimationComplete) {
      return child;
    }
    return CopyOfEntranceAnimation(
      animation: _formElementAnimations[index],
      child: child,
    );
  }

  Widget _buildThemeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _isDarkMode ? Colors.white12 : Colors.black12),
      ),
      child: IconButton(
        icon: Icon(
            _isDarkMode ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded,
            color: aViolet,
            size: 22),
        onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
      ),
    );
  }

  Widget _buildLabel(String t) {
    final labelColor = _isDarkMode ? Colors.blueGrey : pViolet.withOpacity(0.7);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 6),
      child: Text(t.toUpperCase(),
          style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5)),
    );
  }

  Widget _buildTextField(
    TextEditingController c,
    String h,
    IconData i, {
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onChanged,
    void Function(String)? onSubmitted,
  }) {
    final fieldColor = _isDarkMode
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.02);
    final borderColor = _isDarkMode ? Colors.white10 : pViolet.withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        color: _isDarkMode ? fieldColor : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: c,
        obscureText: obscure,
        cursorColor: aViolet,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: TextStyle(
            color: _isDarkMode ? Colors.white : pViolet,
            fontWeight: FontWeight.w600,
            fontSize: 16),
        decoration: InputDecoration(
          hintText: h,
          hintStyle: const TextStyle(
              color: Colors.blueGrey,
              fontSize: 15,
              fontWeight: FontWeight.w400),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(i, color: aViolet, size: 24),
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: suffix,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 24),
        ),
      ),
    );
  }
}

class CopyOfEntranceAnimation extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const CopyOfEntranceAnimation({
    super.key,
    required this.animation,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }
}

class _MovingBackground extends StatefulWidget {
  final bool isDarkMode;
  final bool isPaused;
  const _MovingBackground({
    required this.isDarkMode,
    this.isPaused = false,
  });

  @override
  _MovingBackgroundState createState() => _MovingBackgroundState();
}

class _MovingBackgroundState extends State<_MovingBackground>
    with TickerProviderStateMixin {
  AnimationController? _controller;
  List<_MovingShape> _shapes = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) return;

    _controller = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );

    _generateShapes();

    if (!widget.isPaused) {
      _controller!.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _MovingBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kIsWeb) return;
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        _controller?.stop();
      } else {
        _controller?.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _generateShapes() {
    _shapes = List.generate(
      6,
      (index) => _MovingShape(
        color: _randomColor(),
        size: _random.nextDouble() * 100 + 50,
        x: _random.nextDouble() * 1.5,
        y: _random.nextDouble() * 1.5,
        speed: _random.nextDouble() * 0.003 + 0.001,
        direction: _random.nextBool() ? 1 : -1,
      ),
    );
  }

  Color _randomColor() {
    return widget.isDarkMode
        ? Color.fromRGBO(
            _random.nextInt(50) + 50,
            _random.nextInt(50) + 50,
            _random.nextInt(50) + 50,
            _random.nextDouble() * 0.2 + 0.1,
          )
        : Color.fromRGBO(
            _random.nextInt(50) + 200,
            _random.nextInt(50) + 200,
            _random.nextInt(50) + 200,
            _random.nextDouble() * 0.2 + 0.1,
          );
  }

  void _updateShapes() {
    for (var shape in _shapes) {
      shape.x += shape.speed * shape.direction;
      shape.y += shape.speed * shape.direction * 0.5;

      if (shape.x > 1.5 || shape.x < -0.5 || shape.y > 1.5 || shape.y < -0.5) {
        shape.x = _random.nextDouble() * 1.5;
        shape.y = _random.nextDouble() * 1.5;
        shape.speed = _random.nextDouble() * 0.003 + 0.001;
        shape.direction = _random.nextBool() ? 1 : -1;
        shape.color = _randomColor();
        shape.size = _random.nextDouble() * 100 + 50;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Container(
        decoration: BoxDecoration(
            gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.01),
            Colors.transparent
          ],
          stops: const [0.0, 0.6, 1.0],
        )),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller!,
        builder: (context, child) {
          _updateShapes();
          return Stack(
            children: _shapes.map((shape) {
              return Positioned.fill(
                child: Align(
                  alignment: Alignment(shape.x * 2 - 1, shape.y * 2 - 1),
                  child: Transform.scale(
                    scale: shape.size / 150,
                    child: Opacity(
                      opacity: shape.color.opacity,
                      child: Container(
                        width: shape.size,
                        height: shape.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              shape.color.withOpacity(0.8),
                              shape.color.withOpacity(0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _MovingShape {
  Color color;
  double size;
  double x;
  double y;
  double speed;
  int direction;

  _MovingShape({
    required this.color,
    required this.size,
    required this.x,
    required this.y,
    required this.speed,
    required this.direction,
  });
}
