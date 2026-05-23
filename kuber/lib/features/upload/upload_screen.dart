import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
// NOTE: Adjust this path if your folder structure is different
import '../../providers/theme_provider.dart'; 
import '../../core/utils/api_service.dart';
import '../dashboard/dashboard_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isLoading = false;

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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.isDarkMode;
    
    final Color bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA);
    final Color textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_rounded, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 24),
              Text("Upload Statement", 
                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 12),
              Text("Upload your bank CSV to let Kuber analyze your spending habits.", 
                   textAlign: TextAlign.center, 
                   style: TextStyle(color: textColor.withOpacity(0.6))),
              const SizedBox(height: 48),
              
              // --- THIS IS THE BLOCK THAT WAS MISSING ---
              _isLoading 
                ? const CircularProgressIndicator(color: Colors.blueAccent)
                : ElevatedButton.icon(
                    onPressed: _pickAndUploadFile,
                    icon: const Icon(Icons.folder_open, color: Colors.white),
                    label: const Text("Select CSV File"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}