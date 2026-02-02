import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart'; //ito ay external packages hehe
import 'package:lucide_icons/lucide_icons.dart';

class UEMSLoginPage extends StatefulWidget {
  const UEMSLoginPage({super.key});

  @override
  State<UEMSLoginPage> createState() => _UEMSLoginPageState();
}

class _UEMSLoginPageState extends State<UEMSLoginPage>
    with TickerProviderStateMixin {
  static const Color primaryDark = Color(0xFF0F172A);
  static const Color secondaryDark = Color(0xFF1E1B4B);
  static const Color tertiaryDark = Color(0xFF020617);
  static const Color accentColor = Color(0xFF3B82F6);
  static const Color successColor = Color(0xFF69F0AE);

  late AnimationController _bgController;
  late Animation<Color?> _bgAnimation;

  late AnimationController _entranceController;
  late Animation<double> _formOpacity;
  late Animation<Offset> _formSlide;

  final List<Map<String, dynamic>> _roles = [
    {'id': 'student', 'label': 'Student', 'icon': LucideIcons.graduationCap},
    {'id': 'professor', 'label': 'Professor', 'icon': LucideIcons.user},
    {'id': 'pchair', 'label': 'Chair', 'icon': LucideIcons.shieldCheck},
    {'id': 'office', 'label': 'Office', 'icon': LucideIcons.building2},
    {'id': 'admin', 'label': 'Admin', 'icon': LucideIcons.briefcase},
  ];

  String _selectedRole = 'student';
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);

    _bgAnimation = ColorTween(
      begin: primaryDark,
      end: secondaryDark,
    ).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    );

    _formSlide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
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

  @override
  void dispose() {
    _bgController.dispose();
    _entranceController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_idController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            "Missing credentials. Authentication required.",
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Colors.redAccent.shade400,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const Icon(LucideIcons.shieldCheck, color: successColor, size: 24),
            const SizedBox(width: 15),
            Text(
              'Processing Secure Authentication...',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
        backgroundColor: tertiaryDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: tertiaryDark,
      body: AnimatedBuilder(
        animation: _bgAnimation,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_bgAnimation.value ?? primaryDark, tertiaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.03,
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
                      ? (size.width > 1200 ? 1100 : size.width * 0.95)
                      : size.width,
                  constraints: BoxConstraints(
                    minHeight: isDesktop ? 650 : 0,
                    maxHeight: isDesktop ? 750 : double.infinity,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 80,
                        offset: const Offset(0, 40),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (isDesktop) _buildLeftBanner(),
                      Expanded(
                        flex: isDesktop
                            ? 6
                            : 1, // Balanced ratio for the login form
                        child: _buildRightForm(isDesktop),
                      ),
                    ],
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
        decoration: const BoxDecoration(
          color: primaryDark,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            bottomLeft: Radius.circular(32),
          ),
        ),
        padding: const EdgeInsets.all(60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    LucideIcons.school,
                    color: accentColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  "UEMS",
                  style: GoogleFonts.orbitron(
                    color: Colors.white,
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
                color: Colors.white,
                fontSize: 42, // Adjusted for better fit
                fontWeight: FontWeight.w900,
                height: 1.05,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: 45,
              height: 6,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              "The next generation administrative core for Colleges and Universities. Designed for ultimate security, seamless academic integration, and real-time efficiency.",
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.lock, color: successColor, size: 20),
              const SizedBox(width: 14),
              Text(
                "AES-256 BANK-GRADE ENCRYPTION",
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10, // Slightly smaller for better fit
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightForm(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(
        isDesktop ? 50.0 : 32.0,
      ), // Reduced desktop padding to prevent text wrap
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Portal Access",
            style: GoogleFonts.inter(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: primaryDark,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Secure gateway for authorized personnel and students.",
            style: GoogleFonts.inter(
              color: Colors.blueGrey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),

          _buildRoleSelector(),

          const SizedBox(height: 30),
          _buildInputField(
            controller: _idController,
            label: _selectedRole == 'student'
                ? "Identification Number"
                : "Insert Employee ID",
            hint: _selectedRole == 'student'
                ? "e.g. 2023-10294"
                : "e.g. F-92841",
            icon: LucideIcons.user,
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _passwordController,
            label: "Insert Password",
            hint: "••••••••",
            icon: LucideIcons.shield,
            isPassword: true,
          ),

          const SizedBox(height: 40),
          _buildLoginButton(),

          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  "Trouble signing in?",
                  style: GoogleFonts.inter(
                    color: Colors.blueGrey.shade400,
                    fontSize: 13,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    "Contact System Administrator",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
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

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueGrey.shade100.withOpacity(0.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _roles.map((role) {
            bool isSelected = _selectedRole == role['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedRole = role['id']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      role['icon'],
                      size: 16,
                      color: isSelected
                          ? accentColor
                          : Colors.blueGrey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      role['label'],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: isSelected
                            ? primaryDark
                            : Colors.blueGrey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
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
              color: Colors.blueGrey.shade700,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          cursorColor: accentColor,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: primaryDark,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(icon, color: Colors.blueGrey.shade300, size: 20),
            ),
            suffixIcon: isPassword
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? LucideIcons.eye
                            : LucideIcons.eyeOff,
                        size: 18,
                        color: Colors.blueGrey.shade300,
                      ),
                      onPressed: () => setState(
                        () => _isPasswordVisible = !_isPasswordVisible,
                      ),
                    ),
                  )
                : null,
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Colors.blueGrey.shade200,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blueGrey.shade100),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.blueGrey.shade100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: accentColor, width: 2),
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "SECURE PORTAL ACCESS",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.chevronRight, size: 20),
                ],
              ),
      ),
    );
  }
}
//ehhehehehheheeheehehehehheheheheheh
//minecraft si darlene
