import 'dart:math'; // <-- Added for the doodles
import 'package:flutter/material.dart';
import 'package:kuber/core/utils/auth_service.dart';
import 'package:kuber/features/upload/upload_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color themeAccent = const Color(0xFFFFD700); // premiumGold
    final Color glassCardColor = const Color(0xFF0A3A50).withOpacity(0.65);
    final Color textColor = Colors.white;
    final Color subTextColor = const Color(0xFFA4C2BC);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF125C7A), Color(0xFF030D14)],
            stops: [0.0, 0.85],
          ),
        ),
        child: Stack(
          children: [
            // --- 1. THE DOODLE LAYER ---
            Positioned.fill(
              child: CustomPaint(
                painter: _AuthDoodlePainter(
                  color: themeAccent.withOpacity(0.15), // Subtle gold doodles
                ),
              ),
            ),
            
            // --- 2. THE MAIN UI LAYER ---
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 90,
                          width: 90,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            shape: BoxShape.circle,
                            border: Border.all(color: themeAccent.withOpacity(0.15), width: 1.5),
                            image: const DecorationImage(
                              image: AssetImage('assets/logo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'INITIALIZE VAULT',
                          style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 2.5, fontSize: 22),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure your financial future with Kuber',
                          style: TextStyle(color: subTextColor, fontSize: 13, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 36),
                        Container(
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: glassCardColor,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: themeAccent.withOpacity(0.18)),
                            boxShadow: [
                              BoxShadow(
                                color: themeAccent.withOpacity(0.06),
                                blurRadius: 25,
                                spreadRadius: 3,
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline_rounded,
                                textColor: textColor,
                                subTextColor: subTextColor,
                                themeAccent: themeAccent,
                              ),
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                textColor: textColor,
                                subTextColor: subTextColor,
                                themeAccent: themeAccent,
                              ),
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                isVisible: _isPasswordVisible,
                                onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                                textColor: textColor,
                                subTextColor: subTextColor,
                                themeAccent: themeAccent,
                              ),
                              const SizedBox(height: 18),
                              _buildTextField(
                                controller: _confirmPasswordController,
                                label: 'Confirm Password',
                                icon: Icons.lock_reset_rounded,
                                isPassword: true,
                                isVisible: _isConfirmPasswordVisible,
                                onToggleVisibility: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                                textColor: textColor,
                                subTextColor: subTextColor,
                                themeAccent: themeAccent,
                              ),
                              const SizedBox(height: 32),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () async {
                                    if (_passwordController.text != _confirmPasswordController.text) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.redAccent),
                                      );
                                      return;
                                    }
                                    setState(() { _isLoading = true; });
                                    final user = await _authService.registerWithEmailPassword(
                                      _emailController.text,
                                      _passwordController.text,
                                    );
                                    if (!mounted) return;
                                    setState(() { _isLoading = false; });

                                    if (user != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Vault Created Successfully!'), backgroundColor: Colors.green),
                                      );
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (context) => const UploadScreen()),
                                        (route) => false,
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Registration failed. Try again.'), backgroundColor: Colors.redAccent),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeAccent,
                                    foregroundColor: Colors.black87,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    elevation: 0,
                                  ),
                                  child: _isLoading 
                                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3))
                                      : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 15)),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: subTextColor.withOpacity(0.2), thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Text('OR', style: TextStyle(color: subTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  Expanded(child: Divider(color: subTextColor.withOpacity(0.2), thickness: 1)),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildGoogleButton(themeAccent),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have a vault? ", style: TextStyle(color: subTextColor, fontSize: 13)),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Text(
                                "Access Here",
                                style: TextStyle(color: themeAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleButton(Color themeAccent) {
    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading || _isGoogleLoading ? null : () async {
          setState(() { _isGoogleLoading = true; });
          final user = await _authService.signInWithGoogle();
          if (!mounted) return;
          setState(() { _isGoogleLoading = false; });

          if (user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vault Access Granted!'), backgroundColor: Colors.green),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const UploadScreen()),
              (route) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google Sign-In canceled or failed.'), backgroundColor: Colors.redAccent),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          backgroundColor: Colors.white.withOpacity(0.04),
        ),
        child: _isGoogleLoading
            ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: themeAccent, strokeWidth: 3))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Text('G', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  const Text('Continue with Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5)),
                ],
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
    required Color textColor,
    required Color subTextColor,
    required Color themeAccent,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor, fontSize: 14),
        prefixIcon: Icon(icon, color: subTextColor, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: subTextColor, size: 20),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: subTextColor.withOpacity(0.18))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: themeAccent, width: 1.8)),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}

// --- THE DOODLE PAINTER ---
// --- THE INDIAN MOTIF DOODLE PAINTER ---
// --- THE ELEGANT PADMA & WAVES PAINTER ---
// --- THE MACRO PADMA & WAVES PAINTER ---
// --- THE MACRO PADMA & WAVES PAINTER ---
class _AuthDoodlePainter extends CustomPainter {
  final Color color;
  _AuthDoodlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5 // Slightly thicker to hold up at a massive scale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. THE MASSIVE PADMA (Spans the screen)
    _drawMassiveLotus(canvas, size, paint);

    // 2. THE ELEGANT LINES (Anchors the bottom right)
    _drawSweepingLines(canvas, size, paint);
  }

  void _drawMassiveLotus(Canvas canvas, Size size, Paint paint) {
    canvas.save();
    
    // 1. Anchor it slightly off-screen to the left, and a bit lower
    double xPos = -size.width * 0.05; 
    double yPos = size.height * 0.7; 
    canvas.translate(xPos, yPos);
    
    // 2. A gentle tilt (about 15 degrees) to fan them elegantly across
    canvas.rotate(0.25); 

    // 3. Perfect Scale: 90% of screen height. Big enough to be a macro-background, 
    // but contained enough to keep the petal shapes intact.
    double s = size.height * 0.9; 

    // PETAL 1: Center Petal (Points tall and slightly right)
    Path centerPetal = Path();
    centerPetal.moveTo(0, s * 0.1); // Base of the flower
    centerPetal.quadraticBezierTo(s * 0.4, -s * 0.4, 0, -s); // Right curve up to tip
    centerPetal.quadraticBezierTo(-s * 0.4, -s * 0.4, 0, s * 0.1); // Left curve down
    canvas.drawPath(centerPetal, paint);

    // PETAL 2: Middle Right Petal (The elegant inner sweep)
    Path r1 = Path();
    r1.moveTo(0, s * 0.1);
    // Curves out to the right, ends at a distinct tip
    r1.quadraticBezierTo(s * 0.6, -s * 0.1, s * 0.75, -s * 0.6); 
    r1.quadraticBezierTo(s * 0.3, -s * 0.05, 0, s * 0.1); 
    canvas.drawPath(r1, paint);

    // PETAL 3: Outer Right Petal (The widest arch reaching across the dark space)
    Path r2 = Path();
    r2.moveTo(0, s * 0.1);
    r2.quadraticBezierTo(s * 1.0, s * 0.2, s * 1.1, -s * 0.1); 
    r2.quadraticBezierTo(s * 0.6, s * 0.2, 0, s * 0.1); 
    canvas.drawPath(r2, paint);

    // Subtle base/water ripples under the flower
    canvas.drawLine(Offset(-s * 0.2, s * 0.25), Offset(s * 0.8, s * 0.25), paint);
    canvas.drawLine(Offset(-s * 0.2, s * 0.35), Offset(s * 0.5, s * 0.35), paint);

    canvas.restore();
  }

  void _drawSweepingLines(Canvas canvas, Size size, Paint paint) {
    for (int i = 0; i < 8; i++) {
      Path wave = Path();
      
      double startX = size.width * (0.35 + (i * 0.1));
      double endY = size.height * (0.35 + (i * 0.1));

      wave.moveTo(startX, size.height);
      
      wave.cubicTo(
        startX + size.width * 0.15, size.height * 0.8, 
        size.width * 0.8, endY + size.height * 0.15,   
        size.width, endY                               
      );
      
      canvas.drawPath(wave, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}