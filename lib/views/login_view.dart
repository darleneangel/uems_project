import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

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
      final client = SupabaseService().client;
      final results = await client
          .from('profiles')
          .select('*, student_details(*), employee_details(*)')
          .ilike('user_id_number', id)
          .eq('password_hash', pass);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (results.isNotEmpty) {
        _loggedInUserData = results.first;
        final String role =
            (_loggedInUserData!['role'] as String).toLowerCase();
        _routeToDashboard(role);
      } else {
        _showError("Identity Mismatch. Please check your credentials.");
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      _showError("Sync Error: Unable to reach academic core.");
    }
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
        return AdminDashboardView(onLogout: _resetToLogin);
      case 'admission_dashboard':
        return AdmissionDashboardView(onLogout: _resetToLogin);
      case 'registrar_dashboard':
        return RegistrarDashboardView(onLogout: _resetToLogin);
      case 'hr_dashboard':
        return HrDashboardView(onLogout: _resetToLogin);
      case 'accounting_dashboard':
        return AccountingDashboardView(onLogout: _resetToLogin);
      case 'teacher_dashboard':
        return TeacherDashboardView(
            userData: _loggedInUserData!, onLogout: _resetToLogin);
      case 'program_chair_dashboard':
        // THE FIX: Relay the 6001 data to the Dashboard constructor
        return ProgramChairDashboardView(
            userData: _loggedInUserData!, onLogout: _resetToLogin);
      case 'welcome_uemssp':
        return _buildWelcomeLoading();
      default:
        return _buildSplitLogin();
    }
  }

  void _resetToLogin() => setState(() {
        _currentView = 'login';
        _idController.clear();
        _passwordController.clear();
        _formController.forward(from: 0.0);
      });

  Widget _buildSplitLogin() {
    final bgColor = _isDarkMode ? tDark : const Color(0xFFF1F5F9);
    final cardColor = _isDarkMode ? const Color(0xFF160D2B) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : pViolet;

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
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [pViolet, sViolet, aViolet],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -50,
                          right: -50,
                          child: _buildBlurNode(
                              200, Colors.white.withOpacity(0.08)),
                        ),
                        Positioned(
                          bottom: 100,
                          left: -100,
                          child: _buildBlurNode(300, aViolet.withOpacity(0.15)),
                        ),
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
                                  "UEMS: The Intelligent Core for Academic Excellence at Bright Future Academy.",
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
                                      fontWeight: FontWeight.w900,
                                      color: textColor,
                                      letterSpacing: -2))),
                          _animateEntrance(
                              1,
                              Text(
                                  "Initialize your secure institutional session.",
                                  style: TextStyle(
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
                                  Checkbox(
                                    value: _rememberMe,
                                    activeColor: aViolet,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6)),
                                    onChanged: (v) =>
                                        setState(() => _rememberMe = v!),
                                  ),
                                  Text("Trust this device",
                                      style: TextStyle(
                                          color: textColor.withOpacity(0.5),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                  const Spacer(),
                                  TextButton(
                                      onPressed: () {},
                                      child: const Text("Forgot Password?",
                                          style: TextStyle(
                                              color: aViolet,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w900))),
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
                                    backgroundColor: sViolet,
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
    return Scaffold(
      backgroundColor: tDark,
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
                      color: Colors.white,
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
                        backgroundColor: Colors.white.withOpacity(0.05),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Synchronizing encrypted academic pipeline...",
                        style: TextStyle(
                            color: Colors.blueGrey,
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

  Widget _buildBlurNode(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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

  Widget _buildLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 6),
        child: Text(t.toUpperCase(),
            style: const TextStyle(
                color: Colors.blueGrey,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5)),
      );

  Widget _buildTextField(TextEditingController c, String h, IconData i,
      {bool obscure = false, Widget? suffix}) {
    final fieldColor = _isDarkMode
        ? Colors.white.withOpacity(0.04)
        : Colors.black.withOpacity(0.02);
    final borderColor = _isDarkMode ? Colors.white10 : Colors.black12;

    return Container(
      decoration: BoxDecoration(
        color: fieldColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: TextField(
        controller: c,
        obscureText: obscure,
        cursorColor: aViolet,
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
