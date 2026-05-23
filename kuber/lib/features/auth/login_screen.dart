import 'package:flutter/material.dart';
import 'register_screen.dart';
import '/features/upload/upload_screen.dart';
import '/core/utils/auth_service.dart'; // 👈 Ensure this path points to your AuthService file!
// import '../dashboard/dashboard_screen.dart'; // 👈 Import your next screen here

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- Firebase Auth & Controllers ---
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false; // Tracks the login spinner state

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Syncing with the project's dynamic theme variables
    final Color themeAccent = const Color(0xFFFFD700); // premiumGold
    final Color glassCardColor = const Color(0xFF0A3A50).withOpacity(0.65);
    final Color textColor = Colors.white;
    final Color subTextColor = const Color(0xFFA4C2BC);
    
    return Scaffold(
      body: Container(
        // The deep background gradient (matching the dashboard)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF125C7A), Color(0xFF030D14)],
            stops: [0.0, 0.85],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ==========================================
                  // 🌟 Custom KUBER Logo Section 🌟
                  // ==========================================
                  Container(
                    height: 120, // Explicit sizing to hold the geometry
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      shape: BoxShape.circle,
                      border: Border.all(color: themeAccent.withOpacity(0.15), width: 1.5),
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.png'),
                        fit: BoxFit.cover, // Crops out the rectangular corners completely
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  // The stylized text title remains below the logo asset
                  Text(
                    'KUBER AI',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0, // Wider tracking for the title
                      fontSize: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome back to your financial vault',
                    style: TextStyle(color: subTextColor, fontSize: 13, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 50),

                  // ==========================================
                  // --- GLASSMORPHIC LOGIN CARD ---
                  // ==========================================
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
                        // Email Field
                        _buildTextField(
                          controller: _emailController, // 👈 Hooked up to controller
                          label: 'Email',
                          icon: Icons.email_outlined,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          themeAccent: themeAccent,
                        ),
                        const SizedBox(height: 22),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController, // 👈 Hooked up to controller
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          themeAccent: themeAccent,
                        ),
                        const SizedBox(height: 14),

                        // Forgot Password Link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Password reset logic
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(color: themeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ==========================================
                        // 🌟 FIREBASE LOGIN BUTTON 🌟
                        // ==========================================
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () async {
                              setState(() { _isLoading = true; });

                              // 1. Call Firebase Auth Service
                              final user = await _authService.signInWithEmailPassword(
                                _emailController.text,
                                _passwordController.text,
                              );

                              if (!mounted) return;
                              setState(() { _isLoading = false; });

                              // 2. Handle the response
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
                              foregroundColor: Colors.black87, // High contrast against the gold
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                            ),
                            // Swaps to a loading spinner when authenticating
                            child: _isLoading 
                                ? const SizedBox(
                                    height: 24, 
                                    width: 24, 
                                    child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 3)
                                  )
                                : const Text(
                                    'ACCESS VAULT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.8,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // --- REGISTER NAVIGATION ---
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
                          style: TextStyle(
                            color: themeAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            fontSize: 13,
                          ),
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
    );
  }

  // Helper function for perfectly styled, interactive input fields
  Widget _buildTextField({
    required TextEditingController controller, // 👈 Added controller requirement
    required String label,
    required IconData icon,
    bool isPassword = false,
    required Color textColor,
    required Color subTextColor,
    required Color themeAccent,
  }) {
    return TextFormField(
      controller: controller, // 👈 Bound controller to the input
      obscureText: isPassword && !_isPasswordVisible,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor, fontSize: 14),
        prefixIcon: Icon(icon, color: subTextColor, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: subTextColor,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.04), // Faint internal fill
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: subTextColor.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: themeAccent, width: 1.8), // Gold focus border
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}