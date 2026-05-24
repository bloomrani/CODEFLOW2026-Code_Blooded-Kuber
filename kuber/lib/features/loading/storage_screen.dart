import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  List<FileSystemEntity> _pdfFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync().where((file) => file.path.endsWith('.pdf')).toList();
      setState(() {
        _pdfFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFile(File file) async {
    await file.delete();
    _loadFiles(); // Refresh list
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF030D14) : const Color(0xFFF5F3F9);
    final accentColor = isDark ? const Color(0xFFFFD700) : const Color(0xFF7E22CE);
    final cardColor = isDark ? const Color(0xFF1A3A45) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Downloaded Reports", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: accentColor))
        : _pdfFiles.isEmpty
            ? Center(child: Text("No PDFs found in local storage.", style: TextStyle(color: textColor)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _pdfFiles.length,
                itemBuilder: (context, index) {
                  final file = File(_pdfFiles[index].path);
                  final fileName = file.path.split('/').last;

                  return Card(
                    color: cardColor,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
                      title: Text(fileName, style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 14)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.share_rounded, color: accentColor),
                            onPressed: () => Share.shareXFiles([XFile(file.path)]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_rounded, color: Colors.red),
                            onPressed: () => _deleteFile(file),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}