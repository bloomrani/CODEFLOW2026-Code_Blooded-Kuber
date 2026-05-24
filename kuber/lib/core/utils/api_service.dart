import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // 🌟 REQUIRED FOR WEB: Allows us to handle raw byte streams
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart'; 

class ApiService {
  
  // ==========================================
  // 📱 MOBILE APPROACH (Android / iOS / Desktop)
  // Uses direct local file paths
  // ==========================================
  static Future<Map<String, dynamic>?> analyzeStatementWithAI(File csvFile) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.analyzeEndpoint}'); 
      
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
        'Accept': 'application/json',
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', 
          csvFile.path,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('=== RAW BACKEND JSON (MOBILE) ===');
        print(response.body);
        print('=================================');
        
        return jsonDecode(response.body);
      } else {
        print('Backend Error: ${response.statusCode} - ${response.body}');
        throw Exception('Backend returned error: ${response.statusCode}');
      }
    } catch (e) {
      print('Network Exception: $e');
      throw Exception('Failed to connect to AI backend: $e');
    }
  }

  // ==========================================
  // 🌐 WEB APPROACH (Chrome / Safari / Edge)
  // Uses memory byte arrays (sandbox safe)
  // ==========================================
  static Future<Map<String, dynamic>?> analyzeStatementWithAIWeb(Uint8List fileBytes, String fileName) async {
    try {
      var uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.analyzeEndpoint}'); 
      
      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
        'Accept': 'application/json',
      });

      // Attach the file using fromBytes instead of fromPath
      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      );

      request.files.add(multipartFile);

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('=== RAW BACKEND JSON (WEB) ===');
        print(response.body);
        print('==============================');
        
        return jsonDecode(response.body);
      } else {
        print('Backend Error: ${response.statusCode} - ${response.body}');
        throw Exception('Backend returned error: ${response.statusCode}');
      }
    } catch (e) {
      print('Network Exception: $e');
      throw Exception('Failed to connect to AI backend: $e');
    }
  }
}