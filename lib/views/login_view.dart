import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import 'dart:math';

// Dashboard Imports
import 'student_dashboard_view.dart';
import 'admin_dashboard_view.dart';
import 'accounting_dashboard_view.dart';
import 'admission_dashboard_view.dart';
import 'registrar_dashboard_view.dart';
import 'hr_dashboard_view.dart';
import '../components/program_chair_dashboard_view.dart'; // Verified Path
import '../components/teacher_dashboard_view.dart';
import '../services/supabase_service.dart';
import '../components/hr_panel_content.dart';

import 'forgot_password_handler.dart';

class UEMSLoginPage extends StatefulWidget {
  const UEMSLoginPage({super.key});

  @override
  State<UEMSLoginPage> createState() => _UEMSLoginPageState();
}

class _UEMSLoginPageState extends State<UEMSLoginPage>
    with TickerProviderStateMixin {
  String _currentView = 'login';
  String _targetView = '';
  bool _isDarkMode = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;
  Map<String, dynamic>? _loggedInUserData;

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
  static const Color error = Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    _formController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _formElementAnimations = List.generate(6, (i) {
      return CurvedAnimation(
        parent: _formController,
        curve: Interval(0.1 + (i * 0.1), 1.0, curve: Curves.easeOutQuart),
      );
    });

    _welcomeController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(
            parent: _welcomeController, curve: Curves.easeInOutSine));
    _welcomeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _welcomeController, curve: const Interval(0.0, 0.4)));

    _formController.forward();
  }

  @override
  void dispose() {
    _formController.dispose();
    _welcomeController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final id = _idController.text.trim();
    final pass = _passwordController.text.trim();

    if (id.isEmpty || pass.isEmpty) {
      _showError("Identity Credentials Required");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = SupabaseService();
      final results = await service.client
          .from('profiles')
          .select('*, student_details(*), employee_details(*)')
          .ilike('user_id_number', id)
          .eq('password_hash', pass);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (results.isNotEmpty) {
        // 1. Store the resulting user data
        final userData = results.first;

        // 2. CRITICAL ENFORCEMENT: Verify if the account is Active
        // This logic connects the 'Access & Security' panel settings to the login gate.
        final String status = userData['account_status'] ?? 'Active';

        if (status != 'Active') {
          _showSuspendedDialog(status);
          return; // 🛑 BLOCK ACCESS: Prevents reaching the dashboard
        }

        // 3. Process session data and attendance
        _loggedInUserData = userData;
        final String role =
            (_loggedInUserData!['role'] as String).toLowerCase();

        // Record Check-In Timestamp for employees
        await service.recordAttendanceLogin(_loggedInUserData!['id'], role);

        // 4. Authorized Navigation
        _routeToDashboard(role);
      } else {
        _showError("Identity Mismatch. Please check your credentials.");
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError("Sync Error: Unable to reach academic core.");
    }
  }

  /// Helper to display the institutional access restriction notice
  void _showSuspendedDialog(String status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.report_problem, color: Colors.redAccent),
            const SizedBox(width: 12),
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

  void _resetToLogin() async {
    // --- ADDED: Record Logout Timestamp before clearing data ---
    if (_loggedInUserData != null) {
      await SupabaseService().recordAttendanceLogout(_loggedInUserData!['id']);
    }

    setState(() {
      _currentView = 'login';
      _loggedInUserData = null; // Clear session data
      _idController.clear();
      _passwordController.clear();
      _formController.forward(from: 0.0);
    });
  }

  void _routeToDashboard(String role) {
    String destination = '';
    switch (role) {
      case 'student':
        destination = 'student_portal';
        break;
      case 'admin':
        destination = 'admin_dashboard';
        break;
      case 'registrar':
        destination = 'registrar_dashboard';
        break;
      case 'admission':
        destination = 'admission_dashboard';
        break;
      case 'accounting':
        destination = 'accounting_dashboard';
        break;
      case 'professor':
        destination = 'teacher_dashboard';
        break;
      case 'hr':
        destination = 'hr_dashboard';
        break;
      case 'pchair':
        destination = 'program_chair_dashboard';
        break;
      default:
        _showError("Role '$role' not provisioned.");
        return;
    }

    setState(() {
      _targetView = destination;
      _currentView = 'welcome_uemssp';
    });

    _welcomeController.repeat(reverse: true);
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _welcomeController.stop();
        setState(() => _currentView = _targetView);
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

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      child: _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'student_portal':
        return StudentDashboardView(
            userData: _loggedInUserData!, onLogout: _resetToLogin);
      case 'admin_dashboard':
        return AdminDashboardView(
            userData: _loggedInUserData!, onLogout: _resetToLogin);
      case 'admission_dashboard':
        return AdmissionDashboardView(
            userData: _loggedInUserData!, onLogout: _resetToLogin);
      case 'login':
        return _buildSplitLogin();
      case 'registrar_dashboard':
        return RegistrarDashboardView(
            userData: _loggedInUserData!, onLogout: _resetToLogin);
      case 'hr_panel_content':
      // This case should ideally not be hit if routing is correct.
      // The HRPanelContent is a sub-component, not a top-level dashboard.
      case 'accounting_dashboard':
        return AccountingDashboardView(
            userData: _loggedInUserData!, onLogout: _resetToLogin);
      case 'teacher_dashboard':
        return TeacherDashboardView(
            userData: _loggedInUserData!, onLogout: _resetToLogin);
      case 'program_chair_dashboard':
        // THE FIX: Relay the 6001 data to the Dashboard constructor
        return ProgramChairDashboardView(
            userData: _loggedInUserData!, onLogout: _resetToLogin);
      case 'hr_dashboard': // Corrected routing for HR
        return HRDashboardView(
            userData: _loggedInUserData!, onLogout: _resetToLogin);
      case 'welcome_uemssp':
        return _buildWelcomeLoading();
      default:
        return _buildSplitLogin();
    }
  }

  Widget _buildSplitLogin() {
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF1F5F9);
    final cardColor = _isDarkMode ? const Color(0xFF160D2B) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          // Prevents parent overflow on small viewports
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 1200,
            constraints: const BoxConstraints(
                minHeight: 600,
                maxHeight: 850), // Flex height instead of fixed 800
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(56),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 80,
                    offset: const Offset(0, 40)),
              ],
            ),
            child: Row(
              children: [
                // --- LEFT SIDE: THE BRANDING NODE ---
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(60),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [pViolet, sViolet, aViolet],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      // Use Stack to layer the moving background and content
                      children: [
                        // Moving 3D-like background
                        _MovingBackground(isDarkMode: _isDarkMode),
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
                                  child: const Icon(LucideIcons.school,
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

                // --- RIGHT SIDE: THE ACCESS PORTAL ---
                Expanded(
                  flex: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60,
                        vertical:
                            40), // Reduced from 100 to prevent internal overflow
                    child: SingleChildScrollView(
                      // Allow the form to scroll internally if height is small
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _animateEntrance(
                                  0,
                                  const Icon(LucideIcons.graduationCap,
                                      color: aViolet, size: 40)),
                              _animateEntrance(0, _buildThemeToggle()),
                            ],
                          ),
                          const SizedBox(height: 40),
                          _animateEntrance(
                              1,
                              Text("WELCOME",
                                  style: GoogleFonts.inter(
                                      fontSize: 34,
                                      fontWeight:
                                          FontWeight.w900, // Keep font weight
                                      color:
                                          textColor, // Use theme-aware text color
                                      letterSpacing: -2))),
                          _animateEntrance(
                              1,
                              Text(
                                  "Initialize your secure institutional session.",
                                  style: TextStyle(
                                      // Keep font size and weight
                                      color: Colors.blueGrey.withOpacity(0.7),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500))),
                          const SizedBox(height: 40),
                          _animateEntrance(
                              2, _buildLabel("Identification Number")),
                          _animateEntrance(
                              2,
                              _buildTextField(_idController, "e.g., 202350031",
                                  LucideIcons.user)),
                          const SizedBox(height: 24),
                          _animateEntrance(3, _buildLabel("Password")),
                          _animateEntrance(
                              3,
                              _buildTextField(_passwordController, "••••••••",
                                  LucideIcons.lock,
                                  obscure: !_isPasswordVisible,
                                  suffix: IconButton(
                                    icon: Icon(
                                        _isPasswordVisible
                                            ? LucideIcons.eye
                                            : LucideIcons.eyeOff,
                                        color: aViolet,
                                        size: 20),
                                    onPressed: () => setState(() =>
                                        _isPasswordVisible =
                                            !_isPasswordVisible),
                                  ))),
                          const SizedBox(height: 24),
                          _animateEntrance(
                              4,
                              Row(
                                children: [
                                  // Removed "Trust this device" checkbox as per request
                                  // Checkbox(
                                  //   value: _rememberMe,
                                  //   activeColor: aViolet,
                                  //   shape: RoundedRectangleBorder(
                                  //       borderRadius: BorderRadius.circular(6)),
                                  //   onChanged: (v) =>
                                  //       setState(() => _rememberMe = v!),
                                  // ),
                                  // Text("Trust this device",
                                  //     style: TextStyle(
                                  //         color: textColor.withOpacity(0.5),
                                  //         fontSize: 14,
                                  //         fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  TextButton(
                                      onPressed: () => ForgotPasswordHandler
                                          .showRecoveryFlow(
                                              context, _isDarkMode),
                                      child: const Text("Forgot Password?",
                                          style: TextStyle(
                                              color: aViolet,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900)))
                                ],
                              )),
                          const SizedBox(height: 40),
                          _animateEntrance(
                              3, // Adjusted index due to removal of checkbox
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("VISION",
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight
                                              .w900, // Keep font weight
                                          color: _isDarkMode
                                              ? Colors.white.withOpacity(0.6)
                                              : Colors.black.withOpacity(0.6),
                                          letterSpacing: 1.5)),
                                  Text(
                                      "Bright Future Academy envisions becoming a center of excellence in education that nurtures knowledgeable, skilled, and values-driven individuals who contribute positively to society.",
                                      style: TextStyle(
                                          // Keep font size and height
                                          color: _isDarkMode
                                              ? Colors.white.withOpacity(0.5)
                                              : Colors.black.withOpacity(1),
                                          fontSize: 11,
                                          height: 1.4)),
                                  const SizedBox(height: 16),
                                  Text("MISSION",
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight
                                              .w900, // Keep font weight
                                          color: _isDarkMode
                                              ? Colors.white.withOpacity(0.6)
                                              : Colors.black.withOpacity(0.6),
                                          letterSpacing: 1.5)),
                                  Text(
                                      "Bright Future Academy is committed to: Providing quality and accessible education to all learners. Developing students’ academic competence, creativity, and critical thinking skills. Promoting discipline, respect, and integrity within the school community. Preparing students for higher education, employment, and responsible citizenship. Creating a safe and supportive learning environment.",
                                      style: TextStyle(
                                          color: _isDarkMode
                                              ? Colors.white.withOpacity(0.5)
                                              : Colors.black.withOpacity(1),
                                          fontSize: 11,
                                          height: 1.4)),
                                ],
                              )),
                          const SizedBox(height: 40),
                          _animateEntrance(
                              5,
                              SizedBox(
                                width: double.infinity,
                                height: 65,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: aViolet,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(24)),
                                    elevation: 0,
                                    shadowColor: aViolet.withOpacity(0.4),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 3)
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text("LOG IN",
                                                style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.5,
                                                    fontSize: 14)),
                                            const SizedBox(width: 16),
                                            const Icon(LucideIcons.arrowRight,
                                                size: 20),
                                          ],
                                        ),
                                ),
                              )),
                        ],
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
              // The Academic Core Pulse
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: aViolet.withOpacity(0.5),
                          blurRadius: 80,
                          spreadRadius: 5),
                      BoxShadow(
                          color: sViolet.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 2),
                    ],
                    gradient: const RadialGradient(
                      colors: [aViolet, sViolet, pViolet],
                      stops: [0.3, 0.7, 1.0],
                    ),
                  ),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: const Icon(LucideIcons.shieldCheck,
                          color: Colors.white, size: 80),
                    ),
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
                      // Keep font size, weight, and letter spacing
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
                                ? Colors.blueGrey // Keep blueGrey for dark mode
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

  // --- UI ATOMS (UPGRADED) ---

  Widget _animateEntrance(int index, Widget child) {
    return FadeTransition(
      opacity: _formElementAnimations[index],
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
            .animate(_formElementAnimations[index]),
        child: child,
      ),
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
        icon: Icon(_isDarkMode ? LucideIcons.sun : LucideIcons.moon,
            color: aViolet, size: 22),
        onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
      ),
    );
  }

  Widget _buildLabel(String t) {
    final labelColor = _isDarkMode ? Colors.blueGrey : pViolet.withOpacity(0.7);
    return Padding(
      // Keep padding
      padding: const EdgeInsets.only(bottom: 12, left: 6),
      child: Text(t.toUpperCase(),
          style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5)),
    );
  }

  Widget _buildTextField(TextEditingController c, String h, IconData i,
      {bool obscure = false, Widget? suffix}) {
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
        style: TextStyle(
            color: _isDarkMode ? Colors.white : pViolet,
            fontWeight: FontWeight.w600, // Keep font weight
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

// New widget for the moving background
class _MovingBackground extends StatefulWidget {
  final bool isDarkMode;
  const _MovingBackground({required this.isDarkMode});

  @override
  _MovingBackgroundState createState() => _MovingBackgroundState();
}

class _MovingBackgroundState extends State<_MovingBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  List<_MovingShape> _shapes = [];
  final Random _random = Random();

  // Institutional Palette (copied from _UEMSLoginPageState for self-containment)
  static const Color pViolet = Color(0xFF1E1033);
  static const Color sViolet = Color(0xFF2E1065);
  static const Color aViolet = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration:
          const Duration(seconds: 30), // Longer duration for subtle movement
      vsync: this,
    )..addListener(() {
        setState(() {
          _updateShapes();
        });
      });

    _generateShapes();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateShapes() {
    _shapes = List.generate(
      10, // Number of moving shapes
      (index) => _MovingShape(
        color: _randomColor(),
        size: _random.nextDouble() * 100 + 50, // Size between 50 and 150
        x: _random.nextDouble() * 1.5, // Initial x position (can be off-screen)
        y: _random.nextDouble() * 1.5, // Initial y position
        speed: _random.nextDouble() * 0.005 +
            0.001, // Speed between 0.001 and 0.006
        direction: _random.nextBool() ? 1 : -1, // Random direction
      ),
    );
  }

  Color _randomColor() {
    return widget.isDarkMode
        ? Color.fromRGBO(
            _random.nextInt(50) + 50,
            _random.nextInt(50) + 50,
            _random.nextInt(50) + 50,
            _random.nextDouble() * 0.2 + 0.1, // Opacity between 0.1 and 0.3
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
      shape.y +=
          shape.speed * shape.direction * 0.5; // Slower vertical movement

      // Reset position if it goes off-screen
      if (shape.x > 1.5 || shape.x < -0.5 || shape.y > 1.5 || shape.y < -0.5) {
        shape.x = _random.nextDouble() * 1.5;
        shape.y = _random.nextDouble() * 1.5;
        shape.speed = _random.nextDouble() * 0.005 + 0.001;
        shape.direction = _random.nextBool() ? 1 : -1;
        shape.color = _randomColor();
        shape.size = _random.nextDouble() * 100 + 50;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _shapes.map((shape) {
        return Positioned.fill(
          child: Align(
            alignment: Alignment(
                shape.x * 2 - 1, shape.y * 2 - 1), // Convert 0-1 to -1 to 1
            child: Transform.scale(
              scale: shape.size / 150, // Scale based on size
              child: Opacity(
                opacity: shape.color.opacity,
                child: Container(
                  width: shape.size,
                  height: shape.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: shape.color.withOpacity(
                        1.0), // Use full opacity for the shape itself
                    boxShadow: [
                      BoxShadow(
                        color: shape.color.withOpacity(0.5),
                        blurRadius: shape.size / 4,
                        spreadRadius: shape.size / 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MovingShape {
  Color color;
  double size;
  double x; // 0 to 1, relative to screen width
  double y; // 0 to 1, relative to screen height
  double speed;
  int direction; // 1 for right, -1 for left

  _MovingShape({
    required this.color,
    required this.size,
    required this.x,
    required this.y,
    required this.speed,
    required this.direction,
  });
}
