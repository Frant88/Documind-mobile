import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

class DocumentUploadService {
  Future<bool> uploadDocument({
    required File file,
    required String title,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.documentUpload), // Definito in ApiConstants
    );

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    // Chiavi esatte corrispondenti a Postman (form-data): 'title' e 'file'
    request.fields['title'] = title;
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
      ),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      throw Exception('Errore caricamento (${response.statusCode}): ${response.body}');
    }
  }
}