import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
// Import your student dashboard file here
import 'student_dashboard_view.dart';
import 'admin_dashboard_view.dart';
import 'accounting_dashboard_view.dart';
import 'admission_dashboard_view.dart';
import 'registrar_dashboard_view.dart';
import 'program_chair_dashboard_view.dart';
import 'teacher_dashboard_view.dart';

class UEMSLoginPage extends StatefulWidget {
  const UEMSLoginPage({super.key});

  @override
  State<UEMSLoginPage> createState() => _UEMSLoginPageState();
}

class _UEMSLoginPageState extends State<UEMSLoginPage>
    with TickerProviderStateMixin {
  // Navigation State: 'login', 'admin_dashboard', or 'student_portal'
  String _currentView = 'login';
  bool _isDarkMode = true; // Global theme state

  // Standardized Violet Theme Palette
  static const Color primaryViolet = Color(0xFF2E1065);
  static const Color secondaryViolet = Color(0xFF4C1D95);
  static const Color tertiaryDark = Color(0xFF0F071D);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color surfaceDark = Color(0xFF1E1B4B);
  static const Color successColor = Color(0xFF69F0AE);

  late AnimationController _bgController;
  late Animation<Color?> _bgAnimation;

  late AnimationController _entranceController;
  late Animation<double> _formOpacity;
  late Animation<Offset> _formSlide;

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);

    _updateBgAnimation();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _formOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    );

    _formSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
  }

  void _updateBgAnimation() {
    _bgAnimation = ColorTween(
      begin: _isDarkMode ? primaryViolet : const Color(0xFFEDE9FE),
      end: _isDarkMode ? surfaceDark : Colors.white,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _updateBgAnimation();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entranceController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final id = _idController.text;
    final pass = _passwordController.text;
    setState(() => _isLoading = false);

    // CENTRALIZED ROUTING LOGIC
    if (id == '123' && pass == '123') {
      setState(() => _currentView = 'student_portal');
    } else if (id == '456' && pass == '456') {
      setState(() => _currentView = 'admin_dashboard');
    } else if (id == '789' && pass == '789') {
      setState(() => _currentView = 'admission_dashboard');
    } else if (id == '321' && pass == '321') {
      // Added Accounting ID
      setState(() => _currentView = 'accounting_dashboard');
    } else if (id == '910' && pass == '910' || id == '111' && pass == '111') {
      setState(() => _currentView = 'registrar_dashboard');
    } else if (id == '222' && pass == '222') {
      setState(() => _currentView = 'program_chair_dashboard');
    } else if (id == '333' && pass == '333') {
      setState(() => _currentView = 'teacher_dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid Credentials"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
    _idController.clear();
    _passwordController.clear();
  }

  Widget _buildAnimatedItem(Widget child, int index) {
    final double start = 0.4 + (index * 0.05);
    final double end = (start + 0.4).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ROUTING SWITCH - Directs to your separate files
    switch (_currentView) {
      case 'student_portal':
        return StudentDashboardView(
          onLogout: () => setState(() => _currentView = 'login'),
        );
      case 'admin_dashboard':
        return AdminDashboardView(
          onLogout: () => setState(() => _currentView = 'login'),
        );
      case 'admission_dashboard':
        return AdmissionDashboardView(
          onLogout: () => setState(() => _currentView = 'login'),
        );
      case 'accounting_dashboard':
        return AccountingDashboardView(
          onLogout: () => setState(() => _currentView = 'login'),
        );
      case 'registrar_dashboard':
        return RegistrarDashboardView(
          onLogout: () => setState(() => _currentView = 'login'),
        );
      case 'program_chair_dashboard':
        return ProgramChairDashboardView(
          onLogout: () => setState(() => _currentView = 'login'),
        );
      case 'teacher_dashboard':
        return TeacherDashboardView(
          onLogout: () => setState(() => _currentView = 'login'),
        );
      case 'login':
      default:
        return _buildLoginView();
    }
  }

  Widget _buildLoginView() {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      body: Stack(
        children: [
          // Background Layer
          Container(
            color: _isDarkMode
                ? const Color(0xFF0F071D)
                : const Color(0xFFF1F5F9),
          ),

          // Ambient Background Elements
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              final t = _bgController.value;
              final offset1 = Offset(
                50 * math.sin(t * 2 * math.pi),
                50 * math.cos(t * 2 * math.pi),
              );
              final offset2 = Offset(
                30 * math.sin((t + 0.5) * 2 * math.pi),
                30 * math.cos((t + 0.5) * 2 * math.pi),
              );

              return Stack(
                children: [
                  Positioned(
                    top: -100 + offset1.dy,
                    left: -100 + offset1.dx,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentViolet.withOpacity(0.15),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -100 + offset2.dy,
                    right: -100 + offset2.dx,
                    child: Container(
                      width: 600,
                      height: 600,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            secondaryViolet.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _formOpacity,
                child: SlideTransition(
                  position: _formSlide,
                  child: Container(
                    width: isDesktop ? 1000 : 450,
                    constraints: const BoxConstraints(minHeight: 600),
                    decoration: BoxDecoration(
                      color: _isDarkMode ? surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentViolet.withOpacity(0.15),
                          blurRadius: 80,
                          offset: const Offset(0, 20),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isDesktop
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _buildLeftBanner()),
                                Expanded(child: _buildRightForm(isDesktop)),
                              ],
                            ),
                          )
                        : _buildRightForm(isDesktop),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftBanner() {
    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [const Color(0xFF2E1065), const Color(0xFF4C1D95)]
              : [const Color(0xFF4C1D95), const Color(0xFF6D28D9)],
        ),
        image: DecorationImage(
          image: const NetworkImage(
            "https://www.transparenttextures.com/patterns/cubes.png",
          ),
          repeat: ImageRepeat.repeat,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.1),
            BlendMode.dstATop,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Area (Animated)
          _buildAnimatedItem(
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.graduationCap,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "UEMS PORTAL",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            0,
          ),
          const Spacer(),
          _buildAnimatedItem(
            Text(
              "Welcome!",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            1,
          ),
          const SizedBox(height: 24),
          _buildAnimatedItem(
            Text(
              "Login to access your student portal, view grades, manage subjects, and more. Your academic journey starts here.",
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                height: 1.5,
              ),
            ),
            2,
          ),
          const SizedBox(height: 32),
          _buildAnimatedItem(
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: Text(
                "Learn More",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
            3,
          ),
          const Spacer(),
          // Security Badge
          _buildAnimatedItem(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.shieldCheck,
                    color: successColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Secure Environment",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            4,
          ),
        ],
      ),
    );
  }

  Widget _buildRightForm(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(60),
      color: _isDarkMode ? surfaceDark : Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedItem(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Sign in",
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  onPressed: _toggleTheme,
                  icon: Icon(
                    _isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                    color: _isDarkMode ? Colors.white54 : Colors.grey,
                  ),
                  tooltip: "Toggle Theme",
                ),
              ],
            ),
            0,
          ),

          const SizedBox(height: 48),

          _buildAnimatedItem(
            _buildInputField(
              controller: _idController,
              label: "User Name",
              hint: "Enter Username",
              icon: LucideIcons.user,
            ),
            1,
          ),
          const SizedBox(height: 24),
          _buildAnimatedItem(
            _buildInputField(
              controller: _passwordController,
              label: "Password",
              hint: "Enter your password",
              icon: LucideIcons.lock,
              isPassword: true,
            ),
            2,
          ),

          const SizedBox(height: 32),
          _buildAnimatedItem(_buildLoginButton(), 3),

          const SizedBox(height: 40),
          _buildAnimatedItem(
            Center(
              child: Text(
                "Or sign in with",
                style: GoogleFonts.inter(
                  color: _isDarkMode ? Colors.white54 : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            4,
          ),
          const SizedBox(height: 20),
          _buildAnimatedItem(
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialIcon(LucideIcons.facebook),
                const SizedBox(width: 20),
                _socialIcon(LucideIcons.instagram),
                const SizedBox(width: 20),
                _socialIcon(LucideIcons.twitter),
              ],
            ),
            5,
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isDarkMode ? Colors.white24 : Colors.grey.shade300,
          ),
          shape: BoxShape.circle,
          color: _isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Icon(
          icon,
          size: 20,
          color: _isDarkMode ? Colors.white70 : Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final hintColor = _isDarkMode ? Colors.white38 : Colors.grey[400];
    final fillColor = _isDarkMode
        ? const Color(0xFF2D2445)
        : const Color(0xFFF8FAFC);
    final borderColor = _isDarkMode ? Colors.white10 : Colors.grey[200]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _isDarkMode ? Colors.white70 : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !_isPasswordVisible,
            style: GoogleFonts.inter(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: hintColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: _isDarkMode ? Colors.white30 : Colors.grey[400],
                size: 20,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? LucideIcons.eye
                            : LucideIcons.eyeOff,
                        color: _isDarkMode ? Colors.white30 : Colors.grey[400],
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentViolet,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: accentViolet.withOpacity(0.4),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                "Sign In",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // --- MODERN ADMIN DASHBOARD VIEW ---
  Widget _buildAdminDashboard() {
    final Color dashboardBg = _isDarkMode
        ? tertiaryDark
        : const Color(0xFFF1F5F9);
    final Color sidebarColor = _isDarkMode
        ? const Color(0xFF1E1033)
        : primaryViolet;
    final Color headerColor = _isDarkMode
        ? const Color(0xFF1E1033)
        : Colors.white;
    final Color titleColor = _isDarkMode ? Colors.white : primaryViolet;

    return Scaffold(
      backgroundColor: dashboardBg,
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 280,
            color: sidebarColor,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.shield,
                        color: accentViolet,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "UEMS ADMIN",
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildSidebarHeader("CENTRAL CONTROL"),
                _buildSidebarItem(
                  LucideIcons.layoutDashboard,
                  "System Overview",
                  active: true,
                ),
                _buildSidebarItem(LucideIcons.megaphone, "Post Announcements"),
                const SizedBox(height: 20),
                _buildSidebarHeader("ACADEMIC MANAGEMENT"),
                _buildSidebarItem(
                  LucideIcons.userPlus,
                  "Admission & Enrollment",
                ),
                _buildSidebarItem(LucideIcons.users, "Student Directory"),
                _buildSidebarItem(
                  LucideIcons.graduationCap,
                  "Faculty Management",
                ),
                _buildSidebarItem(LucideIcons.layers, "Subject & Study Loads"),
                _buildSidebarItem(LucideIcons.book, "Grade Recording"),
                const Spacer(),
                const Divider(color: Colors.white10),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const CircleAvatar(
                    backgroundColor: accentViolet,
                    child: Icon(
                      LucideIcons.user,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    "Admin Control",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    "Level: Super Admin",
                    style: GoogleFonts.inter(
                      color: Colors.white30,
                      fontSize: 11,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      LucideIcons.logOut,
                      color: Colors.white54,
                      size: 18,
                    ),
                    onPressed: () => setState(() => _currentView = 'login'),
                  ),
                ),
              ],
            ),
          ),

          // MAIN PANEL
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 80,
                  color: headerColor,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Intelligence Panel",
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _isDarkMode ? Colors.white : primaryViolet,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "SYSTEM STATUS: ACTIVE",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: successColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleTheme,
                        icon: Icon(
                          _isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                          color: accentViolet,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildHeaderAction(LucideIcons.search),
                      const SizedBox(width: 16),
                      _buildHeaderAction(LucideIcons.bell),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatCard(
                              "Total Students",
                              "4,291",
                              LucideIcons.users,
                              accentViolet,
                            ),
                            _buildStatCard(
                              "Enrollment Progress",
                              "82%",
                              LucideIcons.userCheck,
                              Colors.blueAccent,
                            ),
                            _buildStatCard(
                              "Accounting Clearances",
                              "3,102",
                              LucideIcons.wallet,
                              Colors.orangeAccent,
                            ),
                            _buildStatCard(
                              "System Uptime",
                              "99.9%",
                              LucideIcons.activity,
                              successColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _buildControlPanel(
                                "Administrative System Logs",
                                [
                                  _buildLogRow(
                                    "Super Admin posted new Announcement",
                                    "2m ago",
                                    success: true,
                                  ),
                                  _buildLogRow(
                                    "Student #2023-1021 Assessment finalized",
                                    "15m ago",
                                  ),
                                  _buildLogRow(
                                    "Database Sync: records consistent",
                                    "1h ago",
                                    success: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 3,
                              child: Column(
                                children: [
                                  _buildQuickAction(
                                    "Process Admissions",
                                    LucideIcons.userPlus,
                                    Colors.blue,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildQuickAction(
                                    "Database Health",
                                    LucideIcons.database,
                                    successColor,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildQuickAction(
                                    "Security Audit",
                                    LucideIcons.lock,
                                    accentViolet,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Colors.white24,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, {bool active = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: active ? accentViolet.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        visualDensity: VisualDensity.compact,
        leading: Icon(
          icon,
          color: active ? accentViolet : Colors.white60,
          size: 18,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            color: active ? Colors.white : Colors.white60,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withOpacity(0.05)
            : Colors.indigo.withOpacity(0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: _isDarkMode ? Colors.white54 : primaryViolet.withOpacity(0.5),
        size: 20,
      ),
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon, Color color) {
    final Color cardBg = _isDarkMode ? const Color(0xFF1E1033) : Colors.white;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isDarkMode
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
          ),
          boxShadow: _isDarkMode
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 20),
            Text(
              val,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: _isDarkMode ? Colors.white : primaryViolet,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _isDarkMode ? Colors.white38 : Colors.blueGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(String title, List<Widget> children) {
    final Color cardBg = _isDarkMode ? const Color(0xFF1E1033) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: _isDarkMode
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: _isDarkMode ? Colors.white : primaryViolet,
                ),
              ),
              Icon(
                LucideIcons.moreHorizontal,
                color: _isDarkMode ? Colors.white24 : Colors.blueGrey.shade200,
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLogRow(String text, String time, {bool success = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(
            success ? LucideIcons.checkCircle : LucideIcons.activity,
            size: 16,
            color: success
                ? successColor
                : (_isDarkMode ? Colors.white24 : Colors.blueGrey.shade200),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: _isDarkMode ? Colors.white70 : Colors.blueGrey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: _isDarkMode ? Colors.white24 : Colors.blueGrey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color color) {
    final Color cardBg = _isDarkMode ? const Color(0xFF1E1033) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withOpacity(0.03)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              color: _isDarkMode ? Colors.white : primaryViolet,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Icon(
            LucideIcons.chevronRight,
            color: _isDarkMode ? Colors.white12 : Colors.blueGrey.shade200,
            size: 16,
          ),
        ],
      ),
    );
  }
}
