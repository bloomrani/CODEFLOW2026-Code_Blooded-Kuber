import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart'; // Make sure this path is correct for your folders!

class ApiService {
  static Future<Map<String, dynamic>?> analyzeStatementWithAI(File csvFile) async {
    try {
      // Using your constants so you only have to change the ngrok link in one place!
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
        // 👇 THIS IS THE MAGIC DEBUG LINE 👇
        // It will print exactly what the Python/Node backend is giving us.
        print('=== RAW BACKEND JSON ===');
        print(response.body);
        print('========================');
        
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