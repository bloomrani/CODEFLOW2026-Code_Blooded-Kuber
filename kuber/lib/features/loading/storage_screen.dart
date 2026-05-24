import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class StorageScreen extends StatelessWidget {
  const StorageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    final Color premiumGold = const Color(0xFFFFD700); 
    final Color richLavender = const Color(0xFF7E22CE); 
    final Color themeAccent = isDark ? premiumGold : richLavender;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Logic mapped to exactly mirror Dashboard rules
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: isDark 
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF125C7A), Color(0xFF030D14)],
                      stops: [0.0, 0.85], 
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFFFFF), Color(0xFFE9D5FF)],
                      stops: [0.1, 1.0],
                    ),
            ),
          ),
          
          // Dedicated Abstract Line Art layer for the vault
          SizedBox(
            width: double.infinity, 
            height: double.infinity,
            child: CustomPaint(
              painter: StorageLineArtPainter(color: themeAccent.withOpacity(0.08)), 
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                AppBar(
                  title: Text("Storage Vault", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(color: textColor),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Your saved statements will appear here.",
                      style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 16),
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
}

class StorageLineArtPainter extends CustomPainter {
  final Color color;
  StorageLineArtPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3 
      ..style = PaintingStyle.stroke;

    final path1 = Path()..moveTo(size.width * 0.1, 0)..lineTo(size.width * 0.9, size.height * 0.4);
    final path2 = Path()..moveTo(0, size.height * 0.6)..cubicTo(size.width * 0.3, size.height * 0.5, size.width * 0.6, size.height * 0.8, size.width, size.height * 0.7);
    final path3 = Path()..moveTo(size.width * 0.8, size.height)..lineTo(size.width * 0.4, size.height * 0.2);

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}