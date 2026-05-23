import 'package:flutter/material.dart';
import '/core/utils/auth_service.dart'; // 👈 Ensure this path points to your AuthService file!
// import '../dashboard/dashboard_screen.dart'; // 👈 Import your next screen here

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // --- Firebase Auth & Controllers ---
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false; // Tracks the registration spinner state

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
    // Syncing with the project's dynamic theme variables
    final Color themeAccent = const Color(0xFFFFD700); // premiumGold
    final Color glassCardColor = const Color(0xFF0A3A50).withOpacity(0.65);
    final Color textColor = Colors.white;
    final Color subTextColor = const Color(0xFFA4C2BC);
    
    return Scaffold(
      body: Container(
        // The deep background gradient
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ==========================================
                  // --- HEADER & LOGO ---
                  // ==========================================
                  Container(
                    height: 90, // Slightly smaller than login to save vertical space
                    width: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      shape: BoxShape.circle,
                      border: Border.all(color: themeAccent.withOpacity(0.15), width: 1.5),
                      image: const DecorationImage(
                        image: AssetImage('assets/logo.png'),
                        fit: BoxFit.cover, // Perfectly clips the square background!
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'INITIALIZE VAULT',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Secure your financial future with Kuber',
                    style: TextStyle(color: subTextColor, fontSize: 13, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 36),

                  // ==========================================
                  // --- GLASSMORPHIC REGISTRATION CARD ---
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
                        // Full Name Field
                        _buildTextField(
                          controller: _nameController, // 👈 Hooked up to controller
                          label: 'Full Name',
                          icon: Icons.person_outline_rounded,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          themeAccent: themeAccent,
                        ),
                        const SizedBox(height: 18),

                        // Email Field
                        _buildTextField(
                          controller: _emailController, // 👈 Hooked up to controller
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          textColor: textColor,
                          subTextColor: subTextColor,
                          themeAccent: themeAccent,
                        ),
                        const SizedBox(height: 18),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController, // 👈 Hooked up to controller
                          label: 'Password',
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                          isVisible: _isPasswordVisible,
                          onToggleVisibility: () {
                            setState(() => _isPasswordVisible = !_isPasswordVisible);
                          },
                          textColor: textColor,
                          subTextColor: subTextColor,
                          themeAccent: themeAccent,
                        ),
                        const SizedBox(height: 18),

                        // Confirm Password Field
                        _buildTextField(
                          controller: _confirmPasswordController, // 👈 Hooked up to controller
                          label: 'Confirm Password',
                          icon: Icons.lock_reset_rounded,
                          isPassword: true,
                          isVisible: _isConfirmPasswordVisible,
                          onToggleVisibility: () {
                            setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
                          },
                          textColor: textColor,
                          subTextColor: subTextColor,
                          themeAccent: themeAccent,
                        ),
                        const SizedBox(height: 32),

                        // ==========================================
                        // 🌟 FIREBASE REGISTER BUTTON 🌟
                        // ==========================================
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () async {
                              // 1. Password Validation Check
                              if (_passwordController.text != _confirmPasswordController.text) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Passwords do not match!'), backgroundColor: Colors.redAccent),
                                );
                                return;
                              }

                              setState(() { _isLoading = true; });

                              // 2. Call Firebase Auth Service
                              final user = await _authService.registerWithEmailPassword(
                                _emailController.text,
                                _passwordController.text,
                              );

                              if (!mounted) return;
                              setState(() { _isLoading = false; });

                              // 3. Handle the response
                              if (user != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Vault Created Successfully!'), backgroundColor: Colors.green),
                                );
                                
                                // TODO: Uncomment to navigate directly into the app, OR let them use the login screen
                                // Navigator.of(context).pushAndRemoveUntil(
                                //   MaterialPageRoute(builder: (context) => const DashboardScreen()),
                                //   (route) => false,
                                // );
                                
                                // If you just want to send them back to the login screen after registering:
                                // Navigator.of(context).pop();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Registration failed. Try again.'), backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeAccent,
                              foregroundColor: Colors.black87,
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
                                    'CREATE ACCOUNT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ==========================================
                  // --- BACK TO LOGIN NAVIGATION ---
                  // ==========================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have a vault? ", style: TextStyle(color: subTextColor, fontSize: 13)),
                      GestureDetector(
                        onTap: () {
                          // Pops the register screen off the stack to reveal the login screen beneath it
                          Navigator.of(context).pop(); 
                        },
                        child: Text(
                          "Access Here",
                          style: TextStyle(
                            color: themeAccent,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
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

  // Upgraded helper function that accepts state parameters for multiple password fields
  Widget _buildTextField({
    required TextEditingController controller, // 👈 Added controller requirement
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
      controller: controller, // 👈 Bound controller to the input
      obscureText: isPassword && !isVisible,
      style: TextStyle(color: textColor, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor, fontSize: 14),
        prefixIcon: Icon(icon, color: subTextColor, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: subTextColor,
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: subTextColor.withOpacity(0.18)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: themeAccent, width: 1.8),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
      ),
    );
  }
}