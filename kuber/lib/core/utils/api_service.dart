import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class ApiService {
 
  static const String analyzeUrl = 'https://fantastic-exhaust-neutron.ngrok-free.dev/analyze';

  static Future<Map<String, dynamic>?> uploadStatement(PlatformFile file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(analyzeUrl));
      
      
      if (file.bytes != null) {
       
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          file.bytes!,
          filename: file.name,
        ));
      } else if (file.path != null) {
        
        request.files.add(await http.MultipartFile.fromPath(
          'file', 
          file.path!,
        ));
      }

      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        
        return jsonDecode(response.body);
      } else {
        print('Backend Error: \${response.statusCode} - \${response.body}');
        return null;
      }
    } catch (e) {
      print('Upload Exception: $e');
      return null;
    }
  }
}