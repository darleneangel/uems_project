import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

    // Theme Variables
    final Color bgColor = _isDarkMode ? tertiaryDark : const Color(0xFFF8FAFC);
    final Color cardColor = _isDarkMode
        ? surfaceDark.withOpacity(0.9)
        : Colors.white;
    final Color borderColor = _isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _bgAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_bgAnimation.value ?? primaryViolet, bgColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Opacity(
                  opacity: _isDarkMode ? 0.05 : 0.02,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          "https://www.transparenttextures.com/patterns/cubes.png",
                        ),
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                  ),
                ),
                child!,
              ],
            ),
          );
        },
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _formOpacity,
              child: SlideTransition(
                position: _formSlide,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: isDesktop
                      ? (size.width > 1200 ? 1000 : size.width * 0.95)
                      : size.width,
                  constraints: const BoxConstraints(minHeight: 600),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: _isDarkMode
                            ? Colors.black.withOpacity(0.6)
                            : Colors.indigo.withOpacity(0.1),
                        blurRadius: 100,
                        offset: const Offset(0, 50),
                      ),
                    ],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isDesktop) _buildLeftBanner(),
                        Expanded(flex: 7, child: _buildRightForm(isDesktop)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftBanner() {
    return Expanded(
      flex: 5,
      child: Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? primaryViolet : primaryViolet.withOpacity(0.05),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            bottomLeft: Radius.circular(32),
          ),
        ),
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentViolet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    LucideIcons.shield,
                    color: _isDarkMode ? accentViolet : primaryViolet,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  "UEMS",
                  style: GoogleFonts.orbitron(
                    color: _isDarkMode ? Colors.white : primaryViolet,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              "Unified Education\nManagement System",
              style: GoogleFonts.inter(
                color: _isDarkMode ? Colors.white : primaryViolet,
                fontSize: 38,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 45,
              height: 6,
              decoration: BoxDecoration(
                color: accentViolet,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "The modernized administrative core designed for ultimate security, seamless academic integration, and real-time efficiency.",
              style: GoogleFonts.inter(
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.6)
                    : primaryViolet.withOpacity(0.7),
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const Spacer(),
            _buildSecurityBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? Colors.white.withOpacity(0.04)
            : primaryViolet.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.fingerprint,
            color: _isDarkMode ? successColor : Colors.green.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              "SECURE PIPELINE",
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.9)
                    : primaryViolet,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightForm(bool isDesktop) {
    final Color titleColor = _isDarkMode ? Colors.white : primaryViolet;
    final Color subTitleColor = _isDarkMode
        ? Colors.white70
        : Colors.blueGrey.shade600;

    return Padding(
      padding: EdgeInsets.all(isDesktop ? 40.0 : 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "System Login",
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  letterSpacing: -1.2,
                ),
              ),
              IconButton(
                onPressed: _toggleTheme,
                icon: Icon(
                  _isDarkMode ? LucideIcons.sun : LucideIcons.moon,
                  color: accentViolet,
                ),
                tooltip: "Toggle Theme",
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Enter your portal credentials to proceed.",
            style: GoogleFonts.inter(color: subTitleColor, fontSize: 14),
          ),
          const SizedBox(height: 40),

          _buildInputField(
            controller: _idController,
            label: "User Identification",
            hint: "123 (Student) or 456 (Admin)",
            icon: LucideIcons.user,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _passwordController,
            label: "Security Key",
            hint: "••••••••",
            icon: LucideIcons.key,
            isPassword: true,
          ),

          const SizedBox(height: 40),
          _buildLoginButton(),

          const SizedBox(height: 30),
          Center(
            child: TextButton(
              onPressed: () {},
              child: Text(
                "Authorized Personnel Access Only",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: _isDarkMode
                      ? Colors.white38
                      : Colors.blueGrey.shade400,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
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
    final Color labelColor = _isDarkMode
        ? accentViolet.withOpacity(0.8)
        : primaryViolet;
    final Color inputColor = _isDarkMode ? Colors.white : primaryViolet;
    final Color fillColor = _isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: labelColor,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          cursorColor: accentViolet,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: inputColor,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: _isDarkMode ? Colors.white30 : Colors.blueGrey.shade300,
              size: 22,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 20,
                      color: _isDarkMode
                          ? Colors.white30
                          : Colors.blueGrey.shade300,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  )
                : null,
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: _isDarkMode ? Colors.white10 : Colors.blueGrey.shade200,
              fontSize: 14,
            ),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 20,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.transparent,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(
                color: _isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: accentViolet, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentViolet.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentViolet,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "AUTHORIZE LOGIN",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Icon(LucideIcons.arrowRight, size: 22),
                ],
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
