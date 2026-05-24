import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/theme_provider.dart';
import '../../core/utils/auth_service.dart';
import '../auth/login_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF030D14) : const Color(0xFFF5F3F9);
    final accentColor = isDark ? const Color(0xFFFFD700) : const Color(0xFF7E22CE);

    // 🌟 FETCH REAL USER DATA FROM FIREBASE
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    // Safely extract data, providing fallbacks if the user didn't set a name/photo
    final String userName = currentUser?.displayName ?? "Kuber User";
    final String userEmail = currentUser?.email ?? "No email linked";
    const String userRole = "Kuber Beta Tester";

    // 🌟 DEEP PROTOCOL SCANNING: Look inside the specific Google Provider profile metadata
    String photoUrl = "";
    
    if (currentUser != null) {
      // Loop through provider data profiles to find the real, live Google photo token matrix
      for (final profile in currentUser.providerData) {
        if (profile.photoURL != null && profile.photoURL!.isNotEmpty) {
          final String providerUrl = profile.photoURL!;
          // Ignore the unpopulated dummy stub if it appears anywhere in the list
          if (!providerUrl.contains("profile/picture/0")) {
            photoUrl = providerUrl;
            break; // Found the active, real profile picture token
          }
        }
      }
    }

    // High-resolution upscaling logic
    if (photoUrl.isNotEmpty && photoUrl.contains("googleusercontent.com")) {
      photoUrl = photoUrl.replaceAll(RegExp(r'=s\d+-c'), '=s400');
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Account", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🌟 DYNAMIC PROFILE PICTURE CONTAINER WITH SAFE ERROR FALLBACKS
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        // This catches 429, 404, or unexpected network errors gracefully
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint("Profile Image Load Failed (Safe Catch): $error");
                          return Icon(Icons.person_rounded, size: 50, color: accentColor);
                        },
                        // Optional: Displays a loading spinner while downloading the network resource
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              color: accentColor,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : Icon(Icons.person_rounded, size: 50, color: accentColor),
              ),
            ),
            const SizedBox(height: 20),
            
            // 🌟 DYNAMIC TEXT FIELDS
            Text(userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 6),
            Text(userRole, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5, color: textColor.withOpacity(0.6))),
            const SizedBox(height: 4),
            Text(userEmail, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5, color: textColor.withOpacity(0.6))),
            const Spacer(),
            
            // 🌟 FULLY FUNCTIONAL LOGOUT BUTTON
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () async {
                  try {
                    // Show a quick loading indicator so the user knows it's working
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Logging out..."), duration: Duration(seconds: 1))
                    );

                    // Execute backend sign out
                    await AuthService().signOut(); 
                    
                    if(!context.mounted) return;
                    
                    // Nuke the navigation history and send them back to the Login Screen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()), 
                      (route) => false
                    );
                  } catch (e) {
                    // Catch network/auth errors gracefully
                    if(!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to logout: $e"), backgroundColor: Colors.red)
                    );
                  }
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