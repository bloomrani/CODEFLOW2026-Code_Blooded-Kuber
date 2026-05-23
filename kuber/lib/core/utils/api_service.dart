import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {

static const String baseUrl = 'https://fantastic-exhaust-neutron.ngrok-free.dev'; 

static Future<Map<String, dynamic>?> analyzeStatementWithAI(File csvFile) async {
  try {
    var uri = Uri.parse('$baseUrl/analyze'); 
    
    // ... rest of your code ...

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