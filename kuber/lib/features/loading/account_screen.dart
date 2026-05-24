import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
// import '../../core/utils/auth_service.dart'; // Uncomment when auth is ready
// import '../auth/login_screen.dart'; // Uncomment when auth is ready

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF030D14) : const Color(0xFFF5F3F9);
    final accentColor = isDark ? const Color(0xFFFFD700) : const Color(0xFF7E22CE);

    // TODO: Replace these with your actual Auth backend variables later!
    const String userName = "Demo User";
    const String userEmail = "user@codeflow.com";
    const String userRole = "Kuber Beta Tester";

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Account", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: textColor),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50, backgroundColor: accentColor.withOpacity(0.2),
              child: Icon(Icons.person_rounded, size: 50, color: accentColor),
            ),
            const SizedBox(height: 20),
            Text(userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 6),
            Text(userRole, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5, color: textColor.withOpacity(0.6))),
            const SizedBox(height: 4),
            Text(userEmail, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5, color: textColor.withOpacity(0.6))),
            const Spacer(),
            
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () async {
                  // await AuthService().signOut(); 
                  // if(!context.mounted) return;
                  // Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logout clicked!")));
                },
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}