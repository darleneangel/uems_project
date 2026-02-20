import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui';
import 'dart:math' as math;
// Import your student dashboard file here
import 'student_dashboard_view.dart';
import 'admin_dashboard_view.dart';
import 'accounting_dashboard_view.dart';
import 'admission_dashboard_view.dart';
import 'registrar_dashboard_view.dart';
import '../components/program_chair_dashboard_view.dart';
import '../components/teacher_dashboard_view.dart';
import 'hr_dashboard_view.dart';

class UEMSLoginPage extends StatefulWidget {
  const UEMSLoginPage({super.key});

  @override
  State<UEMSLoginPage> createState() => _UEMSLoginPageState();
}

class _UEMSLoginPageState extends State<UEMSLoginPage>
    with TickerProviderStateMixin {
  // Navigation State: 'login', 'admin_dashboard', or 'student_portal'
  String _currentView = 'login';
  String _targetView = ''; // Stores destination after welcome animation
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

  // Welcome Animation Controllers
  late AnimationController _welcomeController;
  late Animation<double> _welcomeScale;
  late Animation<double> _welcomeOpacity;

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

    _welcomeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _welcomeScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _welcomeController, curve: Curves.easeOutBack),
    );

    _welcomeOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _welcomeController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _entranceController.forward();
        // Ensure full screen mode is triggered after the first frame (Mobile)
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
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
    // Restore system overlays when the login view is disposed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _bgController.dispose();
    _entranceController.dispose();
    _welcomeController.dispose();
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

    // CENTRALIZED ROUTING LOGIC
    String destination = '';
    if (id == '123' && pass == '123') {
      destination = 'student_portal';
    } else if (id == '456' && pass == '456') {
      destination = 'admin_dashboard';
    } else if (id == '789' && pass == '789') {
      destination = 'admission_dashboard';
    } else if (id == '321' && pass == '321') {
      destination = 'accounting_dashboard';
    } else if (id == '910' && pass == '910' || id == '111' && pass == '111') {
      destination = 'registrar_dashboard';
    } else if (id == '222' && pass == '222') {
      destination = 'program_chair_dashboard';
    } else if (id == '333' && pass == '333') {
      destination = 'teacher_dashboard';
    } else if (id == '444' && pass == '444') {
      destination = 'hr_dashboard';
    }

    setState(() => _isLoading = false);

    if (destination.isNotEmpty) {
      setState(() {
        _targetView = destination;
        _currentView = 'welcome_animation';
      });

      // Start the welcome sequence
      _welcomeController.forward().then((_) async {
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _currentView = _targetView;
            _welcomeController.reset();
          });
        }
      });
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
      case 'hr_dashboard':
        return HrDashboardView(
          onLogout: () => setState(() => _currentView = 'login'),
        );
      case 'welcome_animation':
        return _buildWelcomeView();
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
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) => Container(
              color:
                  _bgAnimation.value ??
                  (_isDarkMode
                      ? const Color(0xFF0F071D)
                      : const Color(0xFFF1F5F9)),
            ),
          ),

          // Ambient Background Elements
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              final t = _bgController.value;
              final offset1 = Offset(
                100 * math.sin(t * 2 * math.pi),
                100 * math.cos(t * 2 * math.pi),
              );
              final offset2 = Offset(
                80 * math.sin((t + 0.3) * 2 * math.pi),
                80 * math.cos((t + 0.3) * 2 * math.pi),
              );
              final offset3 = Offset(
                120 * math.cos((t + 0.7) * 2 * math.pi),
                120 * math.sin((t + 0.7) * 2 * math.pi),
              );

              return Stack(
                children: [
                  // Ambient Orbs
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
                            accentViolet.withOpacity(_isDarkMode ? 0.2 : 0.1),
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
                            secondaryViolet.withOpacity(
                              _isDarkMode ? 0.15 : 0.05,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: size.height * 0.4 + offset3.dy,
                    left: size.width * 0.3 + offset3.dx,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            successColor.withOpacity(_isDarkMode ? 0.05 : 0.02),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Floating Books
                  ..._buildFloatingBooks(size, t),
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
                    width: isDesktop ? 1100 : 450,
                    constraints: const BoxConstraints(minHeight: 600),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? surfaceDark.withOpacity(0.7)
                          : Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: _isDarkMode
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentViolet.withOpacity(
                            _isDarkMode ? 0.2 : 0.1,
                          ),
                          blurRadius: 80,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Scaffold(
      body: Stack(
        children: [
          // Reuse the animated background for continuity
          AnimatedBuilder(
            animation: _bgAnimation,
            builder: (context, child) => Container(color: _bgAnimation.value),
          ),
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) => Stack(
              children: [
                ..._buildFloatingBooks(
                  MediaQuery.of(context).size,
                  _bgController.value,
                ),
              ],
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _welcomeController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _welcomeOpacity,
                  child: ScaleTransition(
                    scale: _welcomeScale,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Icon with Glow
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: accentViolet.withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentViolet.withOpacity(0.2),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.graduationCap,
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Primary Welcome Text
                        Text(
                          "Welcome to the UEMSSP System",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle / Status
                        Text(
                          "Preparing your personalized workspace...",
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Minimalist Loading Indicator
                        SizedBox(
                          width: 200,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              accentViolet,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingBooks(Size size, double t) {
    final List<Map<String, dynamic>> books = [
      {
        'icon': LucideIcons.book,
        'size': 40.0,
        'top': 0.1,
        'left': 0.1,
        'speed': 1.0,
      },
      {
        'icon': LucideIcons.bookOpen,
        'size': 30.0,
        'top': 0.7,
        'left': 0.8,
        'speed': 1.5,
      },
      {
        'icon': LucideIcons.book,
        'size': 50.0,
        'top': 0.4,
        'left': 0.05,
        'speed': 0.8,
      },
      {
        'icon': LucideIcons.bookOpen,
        'size': 35.0,
        'top': 0.8,
        'left': 0.2,
        'speed': 1.2,
      },
      {
        'icon': LucideIcons.book,
        'size': 25.0,
        'top': 0.2,
        'left': 0.9,
        'speed': 2.0,
      },
    ];

    return books.map((book) {
      final double speed = book['speed'];
      final double xOffset = 30 * math.sin((t * speed) * 2 * math.pi);
      final double yOffset = 50 * math.cos((t * speed) * 2 * math.pi);
      final double rotation = math.sin((t * speed) * math.pi) * 0.2;

      return Positioned(
        top: size.height * book['top'] + yOffset,
        left: size.width * book['left'] + xOffset,
        child: Opacity(
          opacity: _isDarkMode ? 0.15 : 0.08,
          child: Transform.rotate(
            angle: rotation,
            child: Icon(
              book['icon'],
              size: book['size'],
              color: _isDarkMode ? Colors.white : primaryViolet,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildLeftBanner() {
    return Container(
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isDarkMode
              ? [primaryViolet, secondaryViolet]
              : [secondaryViolet, accentViolet],
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
            AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    5 * math.sin(_bgController.value * 2 * math.pi),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: const Icon(
                          LucideIcons.graduationCap,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "UEMSSP",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
              "One Portal. One System. One School. Streamlining education, empowering connection.",
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
              style: ButtonStyle(
                foregroundColor: WidgetStateProperty.all(Colors.white),
                side: WidgetStateProperty.all(
                  const BorderSide(color: Colors.white24),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                overlayColor: WidgetStateProperty.all(
                  Colors.white.withOpacity(0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Learn More",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowRight, size: 16),
                ],
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
      padding: EdgeInsets.all(isDesktop ? 80 : 40),
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
              label: "User ID",
              hint: "Enter User ID",
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

          const SizedBox(height: 16),
          _buildAnimatedItem(
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  "Forgot Password?",
                  style: GoogleFonts.inter(
                    color: accentViolet,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            2,
          ),

          const SizedBox(height: 32),
          _buildAnimatedItem(_buildLoginButton(), 3),
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
    final textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final hintColor = _isDarkMode ? Colors.white38 : Colors.grey[400];
    final fillColor = _isDarkMode
        ? Colors.white.withOpacity(0.05)
        : Colors.grey.shade100;
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
          height: 56,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
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
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
        style:
            ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ).copyWith(
              // FIX: Use WidgetStatePropertyAll to wrap the Color
              shadowColor: WidgetStatePropertyAll(
                accentViolet.withOpacity(0.4),
              ),
              // If you are on an older Flutter version and WidgetStatePropertyAll is not found,
              // use: shadowColor: WidgetStateProperty.all(accentViolet.withOpacity(0.4)),
            ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [accentViolet, secondaryViolet],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            alignment: Alignment.center,
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
        ),
      ),
    );
  }
}
