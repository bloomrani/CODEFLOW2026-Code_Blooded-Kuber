import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:kuber/features/auth/register_screen.dart';
import 'package:kuber/core/utils/auth_service.dart';
import 'package:kuber/features/upload/upload_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color themeAccent = const Color(0xFFFFD700); 
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
                  color: themeAccent.withOpacity(0.15), // Subtle gold
                ),
              ),
            ),
            
            // --- 2. THE MAIN UI LAYER ---
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 120,
                          width: 120,
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
                        const SizedBox(height: 32),
                        Text(
                          'KUBER AI',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Welcome back to your financial vault',
                          style: TextStyle(color: subTextColor, fontSize: 13, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 50),
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
                                controller: _emailController,
                                label: 'Email',
                                icon: Icons.email_outlined,
                                textColor: textColor,
                                subTextColor: subTextColor,
                                themeAccent: themeAccent,
                              ),
                              const SizedBox(height: 22),
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                isPassword: true,
                                textColor: textColor,
                                subTextColor: subTextColor,
                                themeAccent: themeAccent,
                              ),
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    'Forgot Password?',
                                    style: TextStyle(color: themeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : () async {
                                    setState(() { _isLoading = true; });
                                    final user = await _authService.signInWithEmailPassword(
                                      _emailController.text,
                                      _passwordController.text,
                                    );
                                    if (!mounted) return;
                                    setState(() { _isLoading = false; });

                                    if (user != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Vault Access Granted!'), backgroundColor: Colors.green),
                                      );
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(builder: (context) => const UploadScreen()),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Invalid email or password.'), backgroundColor: Colors.redAccent),
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
                                      : const Text('ACCESS VAULT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.8, fontSize: 16)),
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
                        const SizedBox(height: 36),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: TextStyle(color: subTextColor, fontSize: 13)),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) => const RegisterScreen()),
                                );
                              },
                              child: Text(
                                "Create Vault",
                                style: TextStyle(color: themeAccent, fontWeight: FontWeight.bold, letterSpacing: 0.6, fontSize: 13),
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
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const UploadScreen()),
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
    required Color textColor,
    required Color subTextColor,
    required Color themeAccent,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor, fontSize: 14),
        prefixIcon: Icon(icon, color: subTextColor, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: subTextColor, size: 20),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
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

// --- THE PERFECTED PAINTER: A Structured Cluster of 5 Lotuses ---
class _AuthDoodlePainter extends CustomPainter {
  final Color color;
  _AuthDoodlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5 
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. A perfectly spaced, hardcoded cluster of 5 lotuses in the top-left area. 
    // Since we dictate the exact coordinates, they will NEVER overlap.
    
    // Main Lotus (Largest, anchoring the top left)
    _drawCompleteSmallLotus(canvas, paint, Offset(size.width * 0.12, size.height * 0.20), size.height * 0.12, 0.2); 
    
    // Second Lotus (Medium, dropping down and to the right)
    _drawCompleteSmallLotus(canvas, paint, Offset(size.width * 0.28, size.height * 0.38), size.height * 0.08, 0.35);

    // Third Lotus (Small, floating high near the top middle)
    _drawCompleteSmallLotus(canvas, paint, Offset(size.width * 0.35, size.height * 0.12), size.height * 0.06, 0.5);

    // Fourth Lotus (Medium, pushing towards the bottom left edge)
    _drawCompleteSmallLotus(canvas, paint, Offset(size.width * 0.05, size.height * 0.45), size.height * 0.09, 0.1);

    // Fifth Lotus (Small, capping off the bottom of the cluster)
    _drawCompleteSmallLotus(canvas, paint, Offset(size.width * 0.18, size.height * 0.58), size.height * 0.07, 0.25);

    // 2. Sweeping lines anchoring the bottom right
    _drawSweepingLines(canvas, size, paint);
  }

  void _drawCompleteSmallLotus(Canvas canvas, Paint paint, Offset offset, double s, double rotation) {
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(rotation);

    // Center Petal
    Path centerPetal = Path();
    centerPetal.moveTo(0, s * 0.1); 
    centerPetal.quadraticBezierTo(s * 0.35, -s * 0.35, 0, -s); 
    centerPetal.quadraticBezierTo(-s * 0.35, -s * 0.35, 0, s * 0.1); 
    canvas.drawPath(centerPetal, paint);

    // Right Inner Petal
    Path r1 = Path();
    r1.moveTo(0, s * 0.1);
    r1.quadraticBezierTo(s * 0.5, -s * 0.1, s * 0.65, -s * 0.5); 
    r1.quadraticBezierTo(s * 0.3, -s * 0.05, 0, s * 0.1); 
    canvas.drawPath(r1, paint);

    // Right Outer Petal
    Path r2 = Path();
    r2.moveTo(0, s * 0.1);
    r2.quadraticBezierTo(s * 0.8, s * 0.1, s * 0.9, -s * 0.1); 
    r2.quadraticBezierTo(s * 0.5, s * 0.1, 0, s * 0.1); 
    canvas.drawPath(r2, paint);

    // Left Inner Petal 
    Path l1 = Path();
    l1.moveTo(0, s * 0.1);
    l1.quadraticBezierTo(-s * 0.5, -s * 0.1, -s * 0.65, -s * 0.5); 
    l1.quadraticBezierTo(-s * 0.3, -s * 0.05, 0, s * 0.1); 
    canvas.drawPath(l1, paint);

    // Left Outer Petal
    Path l2 = Path();
    l2.moveTo(0, s * 0.1);
    l2.quadraticBezierTo(-s * 0.8, s * 0.1, -s * 0.9, -s * 0.1); 
    l2.quadraticBezierTo(-s * 0.5, s * 0.1, 0, s * 0.1); 
    canvas.drawPath(l2, paint);

    // Centered Ripples under the lotus
    canvas.drawLine(Offset(-s * 0.6, s * 0.25), Offset(s * 0.6, s * 0.25), paint);
    canvas.drawLine(Offset(-s * 0.3, s * 0.35), Offset(s * 0.3, s * 0.35), paint);

    canvas.restore();
  }

  void _drawSweepingLines(Canvas canvas, Size size, Paint paint) {
    // Draws abstract waves only in the dark bottom-right corner
    for (int i = 0; i < 6; i++) {
      Path wave = Path();
      
      double startX = size.width * (0.5 + (i * 0.08));
      double endY = size.height * (0.5 + (i * 0.08));

      wave.moveTo(startX, size.height);
      
      wave.cubicTo(
        startX + size.width * 0.1, size.height * 0.8, 
        size.width * 0.8, endY + size.height * 0.1,   
        size.width, endY                               
      );
      
      canvas.drawPath(wave, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; 
}