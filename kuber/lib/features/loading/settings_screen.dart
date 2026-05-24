import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'account_screen.dart'; 
import 'storage_screen.dart'; 

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF030D14) : const Color(0xFFF5F3F9);
    final accentColor = isDark ? const Color(0xFFFFD700) : const Color(0xFF7E22CE);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Settings", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: isDark ? const Color(0xFF1A3A45) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  activeColor: accentColor,
                  title: Text("Dark Mode", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  value: themeProvider.isDarkMode,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
                Divider(color: textColor.withOpacity(0.1), height: 1),
                ListTile(
                  leading: Icon(Icons.person_rounded, color: accentColor),
                  title: Text("Account & Profile", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen())),
                ),
                Divider(color: textColor.withOpacity(0.1), height: 1),
                ListTile(
                  leading: Icon(Icons.folder_shared_rounded, color: accentColor),
                  title: Text("Storage Mode", style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StorageScreen())),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}