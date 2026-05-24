import 'dart:io';
import 'dart:convert';
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DashboardScreen(analysisData: data)),
        );
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
    
    final Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF4F6F8);
    final Color cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final displayScans = ScanVault.savedScans.reversed.toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("KUBER AI", style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Icon(Icons.cloud_upload_rounded, size: 80, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF6366F1)),
            const SizedBox(height: 24),
            Text("Upload Statement", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 12),
            Text("Upload your bank CSV to let Kuber analyze your spending habits.", 
                textAlign: TextAlign.center, 
                style: TextStyle(color: textColor.withOpacity(0.6))),
            const SizedBox(height: 48),
            
            _isLoading 
              ? CircularProgressIndicator(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF6366F1))
              : ElevatedButton.icon(
                  onPressed: _pickAndUploadFile,
                  icon: const Icon(Icons.folder_open, color: Colors.white),
                  label: const Text("Select CSV File", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            
            const SizedBox(height: 60),

            if (displayScans.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Previous Scans", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDark ? const Color(0xFF38BDF8).withOpacity(0.2) : const Color(0xFF6366F1).withOpacity(0.2),
                        child: Icon(Icons.description_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF6366F1)),
                      ),
                      title: Text("Statement Analysis", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text("Saved on $date", style: TextStyle(color: textColor.withOpacity(0.5))),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
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
    );
  }
}