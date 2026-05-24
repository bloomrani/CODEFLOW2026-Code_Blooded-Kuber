import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

import '../../providers/theme_provider.dart'; 
import '../../core/utils/api_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../loading/settings_screen.dart'; 
import '../../core/utils/scan_vault.dart';

// --- THE PERMANENT VAULT ---
class ScanVault {
  static List<Map<String, dynamic>> savedScans = [];

  static Future<void> loadScans() async {
    final prefs = await SharedPreferences.getInstance();
    final String? scansString = prefs.getString('kuber_saved_scans');
    if (scansString != null) {
      final List<dynamic> decoded = jsonDecode(scansString);
      savedScans = decoded.map((e) => e as Map<String, dynamic>).toList();
    }
  }

  static Future<void> saveScan(Map<String, dynamic> newScan) async {
    final int index = savedScans.indexWhere((scan) => scan['scan_date'] == newScan['scan_date']);
    if (index != -1) {
      savedScans[index] = newScan;
    } else {
      newScan['scan_date'] ??= DateTime.now().toString().substring(0, 16);
      savedScans.add(newScan);
    }
    await _persist();
  }

  static Future<void> deleteScan(String dateId) async {
    savedScans.removeWhere((scan) => scan['scan_date'] == dateId);
    await _persist();
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kuber_saved_scans', jsonEncode(savedScans));
  }
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initVault();
  }
  
  Future<void> _loadVault() async {
    await ScanVault.loadScans();
    if (mounted) setState(() {}); 
  }
  
  Future<void> _initVault() async {
    await ScanVault.loadScans();
    if (mounted) setState(() {}); 
  }

  Future<void> _pickAndUploadFile(String fileExtension) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: [fileExtension],
      withData: true,
    );
    
    if (result == null) return; 

    setState(() => _isLoading = true);
    
    try {
      Map<String, dynamic>? data;

      if (kIsWeb) {
        final bytes = result.files.single.bytes!;
        final fileName = result.files.single.name;
        data = await ApiService.analyzeStatementWithAIWeb(bytes, fileName);
      } else {
        File file = File(result.files.single.path!);
        data = await ApiService.analyzeStatementWithAI(file);
      }
      
      if (mounted && data != null) {
        data['scan_date'] = DateTime.now().toString().substring(0, 16);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => DashboardScreen(analysisData: data!)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    
    final Color premiumGold = const Color(0xFFFFD700); 
    final Color deepGold = const Color(0xFFD4AF37);
    final Color richLavender = const Color(0xFF7E22CE); 
    
    final Color themeAccent = isDark ? premiumGold : richLavender;
    final Color buttonTextColor = isDark ? deepGold : richLavender; 
    
    final Color cardColor = isDark ? const Color(0xFF1A3A45) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E1C24);
    
    final displayScans = ScanVault.savedScans.reversed.toList();

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("KUBER AI", style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, color: themeAccent),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: themeAccent),
            onPressed: () => themeProvider.toggleTheme(!isDark),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: isDark 
                  ? const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF125C7A), Color(0xFF030D14)], stops: [0.0, 0.85])
                  : const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFFFFFF), Color(0xFFE9D5FF)], stops: [0.1, 1.0]),
            ),
          ),
          
          Positioned.fill(
            child: CustomPaint(
              painter: DoodleBackgroundPainter(color: themeAccent.withOpacity(0.12)),
            ),
          ),
          
          SafeArea(
            child: Center( 
              child: ConstrainedBox( 
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.8), 
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: themeAccent.withOpacity(0.3), width: 2), 
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: themeAccent.withOpacity(0.1)),
                              child: Icon(Icons.cloud_upload_rounded, size: 70, color: themeAccent),
                            ),
                            const SizedBox(height: 24),
                            Text("Upload Statement", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(height: 12),
                            Text("Drop your bank CSV or PDF here to let Kuber map out your spending universe.", textAlign: TextAlign.center, style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 15)),
                            const SizedBox(height: 32),
                            
                            _isLoading 
                              ? CircularProgressIndicator(color: themeAccent)
                              : Column(
                                  children: [
                                    _buildStyledButton("Select CSV File", Icons.table_chart_rounded, () => _pickAndUploadFile('csv'), buttonTextColor, themeAccent),
                                    const SizedBox(height: 12),
                                    _buildStyledButton("Select PDF File", Icons.picture_as_pdf_rounded, () => _pickAndUploadFile('pdf'), buttonTextColor, themeAccent),
                                  ],
                                ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),

                      if (displayScans.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Previous Analysis Scans", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
                        ),
                        const SizedBox(height: 16),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: displayScans.length,
                          itemBuilder: (context, index) {
                            final scan = displayScans[index];
                            final String date = scan['scan_date'] ?? "Unknown Date";
                            
                            return Card(
                              color: cardColor,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: ListTile(
                                title: Text(scan['scan_name'] ?? "Statement Analysis", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                subtitle: Text(date, style: TextStyle(color: textColor.withOpacity(0.5))),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                                  onPressed: () async {
                                    await ScanVault.deleteScan(date);
                                    setState(() {});
                                  },
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => DashboardScreen(analysisData: scan)),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledButton(String text, IconData icon, VoidCallback onPressed, Color textColor, Color iconColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor), 
        label: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class DoodleBackgroundPainter extends CustomPainter {
  final Color color;
  DoodleBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 2.0..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final random = Random(42); 

    for (int i = 0; i < 20; i++) {
      double x = random.nextDouble() * size.width; double y = random.nextDouble() * size.height;
      double s = random.nextDouble() * 10 + 5; 
      canvas.drawLine(Offset(x - s, y), Offset(x + s, y), paint);
      canvas.drawLine(Offset(x, y - s), Offset(x, y + s), paint);
    }
    for (int i = 15; i < 30; i++) {
      double x = random.nextDouble() * size.width; double y = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), random.nextDouble() * 15 + 5, paint);
    }
    for (int i = 0; i < 8; i++) {
      double startX = random.nextDouble() * size.width;
      double startY = random.nextDouble() * size.height;
      Path path = Path()..moveTo(startX, startY);
      double currentX = startX; double currentY = startY;
      for(int j = 0; j < 3; j++) {
        currentX += random.nextDouble() * 40 + 20;
        currentY += (random.nextBool() ? 1 : -1) * (random.nextDouble() * 30 + 10);
        path.lineTo(currentX, currentY);
      }
      canvas.drawPath(path, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}