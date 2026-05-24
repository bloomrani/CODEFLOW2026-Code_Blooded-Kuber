import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart'; 
import '../../core/utils/api_service.dart';
import '../dashboard/dashboard_screen.dart';

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
    bool exists = savedScans.any((scan) => scan['scan_date'] == newScan['scan_date']);
    if (!exists) {
      newScan['scan_date'] ??= DateTime.now().toString().substring(0, 16);
      savedScans.add(newScan);
      await _persist();
    }
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

  Future<void> _initVault() async {
    await ScanVault.loadScans();
    if (mounted) setState(() {}); 
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom, 
      allowedExtensions: ['csv']
    );
    
    if (result == null) return; 

    setState(() => _isLoading = true);
    
    try {
      File file = File(result.files.single.path!);
      final data = await ApiService.analyzeStatementWithAI(file);
      
      if (mounted && data != null) {
        data['scan_date'] = DateTime.now().toString().substring(0, 16);
        await ScanVault.saveScan(data); 
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => DashboardScreen(analysisData: data)),
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
    
    // --- CUSTOM COLOR PALETTE ---
    final Color bgColor = isDark ? const Color(0xFF122C34) : const Color(0xFFF5F3F9); 
    final Color cardColor = isDark ? const Color(0xFF1A3A45) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E1C24);
    final Color accentColor = isDark ? const Color(0xFF38BDF8) : const Color(0xFF6366F1);
    
    final Color doodleColor = isDark 
        ? const Color(0xFFFFD54F).withOpacity(0.12) // Yellow Doodles
        : const Color(0xFF9575CD).withOpacity(0.15); // Lavender Doodles

    final displayScans = ScanVault.savedScans.reversed.toList();

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("KUBER AI", style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 1. The Doodly Background Layer
          Positioned.fill(
            child: CustomPaint(
              painter: DoodleBackgroundPainter(color: doodleColor),
            ),
          ),
          
          // 2. The Main Content Layer
          SafeArea(
            child: Center( 
              child: ConstrainedBox( 
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Stylized Upload Card
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.8), 
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: accentColor.withOpacity(0.3), width: 2), 
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor.withOpacity(0.1),
                              ),
                              child: Icon(Icons.cloud_upload_rounded, size: 70, color: accentColor),
                            ),
                            const SizedBox(height: 24),
                            Text("Upload Statement", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(height: 12),
                            Text(
                              "Drop your bank CSV here to let Kuber map out your spending universe.", 
                              textAlign: TextAlign.center, 
                              style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 15, height: 1.4),
                            ),
                            const SizedBox(height: 32),
                            
                            _isLoading 
                              ? CircularProgressIndicator(color: accentColor)
                              : ElevatedButton.icon(
                                  onPressed: _pickAndUploadFile,
                                  icon: const Icon(Icons.auto_awesome_rounded, color: Colors.white), 
                                  label: const Text("Select CSV File", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 50),

                      if (displayScans.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Previous Scans", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: textColor.withOpacity(0.05)), 
                              ),
                              elevation: 0,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.insert_chart_rounded, color: accentColor),
                                ),
                                title: Text("Statement Analysis", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                subtitle: Text(date, style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                                  onPressed: () async {
                                    await ScanVault.deleteScan(date);
                                    setState(() {});
                                  },
                                ),
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (context) => DashboardScreen(analysisData: scan)),
                                  );
                                },
                              ),
                            );
                          },
                        )
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
}

// --- THE DOODLE PAINTER ---
class DoodleBackgroundPainter extends CustomPainter {
  final Color color;
  DoodleBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final random = Random(42); 

    // Pluses
    for (int i = 0; i < 20; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double s = random.nextDouble() * 10 + 5; 
      
      canvas.drawLine(Offset(x - s, y), Offset(x + s, y), paint);
      canvas.drawLine(Offset(x, y - s), Offset(x, y + s), paint);
    }

    // Circles
    for (int i = 0; i < 15; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      double r = random.nextDouble() * 15 + 5; 
      canvas.drawCircle(Offset(x, y), r, paint);
    }

    // Squiggly lines
    for (int i = 0; i < 8; i++) {
      double startX = random.nextDouble() * size.width;
      double startY = random.nextDouble() * size.height;
      
      Path path = Path();
      path.moveTo(startX, startY);
      
      double currentX = startX;
      double currentY = startY;
      
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