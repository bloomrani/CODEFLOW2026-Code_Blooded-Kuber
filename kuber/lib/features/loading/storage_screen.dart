import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/theme_provider.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  List<FileSystemEntity> pdfFiles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPdfFiles();
  }

  Future<void> _fetchPdfFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    
    // Only show .pdf files
    setState(() {
      pdfFiles = files.where((f) => f.path.endsWith('.pdf')).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final Color glassCardColor = isDark ? const Color(0xFF0A3A50).withOpacity(0.65) : Colors.white.withOpacity(0.85);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
           gradient: isDark 
              ? const LinearGradient(colors: [Color(0xFF125C7A), Color(0xFF030D14)])
              : const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE9D5FF)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text("Generated PDF Reports", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                backgroundColor: Colors.transparent, elevation: 0,
              ),
              Expanded(
                child: isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : pdfFiles.isEmpty 
                    ? Center(child: Text("No PDF reports found.", style: TextStyle(color: textColor.withOpacity(0.5))))
                    : // Inside storage_screen.dart, replace the ListView.builder with this:
ListView.builder(
  padding: const EdgeInsets.all(16),
  itemCount: pdfFiles.length,
  itemBuilder: (context, index) {
    final file = File(pdfFiles[index].path);
    final fileName = file.path.split('/').last;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: glassCardColor, borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
        title: Text(fileName, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                // Delete the physical file
                await file.delete();
                // Refresh the list immediately
                _fetchPdfFiles();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PDF deleted")));
              },
            ),
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.blue),
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ],
        ),
      ),
    );
  },
),

              ),
            ],
          ),
        ),
      ),
    );
  }
}