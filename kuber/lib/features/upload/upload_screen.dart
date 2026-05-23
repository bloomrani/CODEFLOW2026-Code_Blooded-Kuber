import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:animate_do/animate_do.dart';


import '../../core/utils/api_service.dart';
import '../dashboard/dashboard_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isUploading = false;

  
  Future<void> _pickBankStatement() async {
    setState(() => _isUploading = true);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'pdf'],
        withData: true, 
      );

      if (result != null) {
        
        final backendResponse = await ApiService.uploadStatement(result.files.first);
        
        if (mounted) {
          if (backendResponse != null) {
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Statement Analyzed Successfully!'),
                backgroundColor: Colors.greenAccent,
              ),
            );
            
            
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DashboardScreen(analysisData: backendResponse), 
              ),
            );
          } else {
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to analyze statement. Check server connection.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
              shape: BoxShape.circle,
               color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                boxShadow: [
                 BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  blurRadius: 120,
                 ),
                ],
             ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kuber AI', 
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Analyze your financial footprint instantly.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                 
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickBankStatement,
                      child: Container(
                        width: double.infinity,
                        height: 280,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _isUploading 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.white.withOpacity(0.08),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: _isUploading
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Kuber is analyzing...',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    'Upload your bank statement',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Supports CSV or PDF formats',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}