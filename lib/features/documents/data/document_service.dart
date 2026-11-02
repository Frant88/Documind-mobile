import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class DocumentService {
  /// Recupera i documenti dall'API di Laravel
  Future fetchDocumenti() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.documents),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        return {'unauthorized': true, 'data': []};
      }

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> lista = [];

        if (decodedData is Map && decodedData['data'] is List) {
          lista = decodedData['data'];
        } else if (decodedData is List) {
          lista = decodedData;
        }

        return {'unauthorized': false, 'data': lista};
      }

      return {'unauthorized': false, 'data': []};
    } catch (e) {
      print('Errore caricamento documenti: $e');
      return {'unauthorized': false, 'data': []};
    }
  }

  /// Effettua la chiamata di logout al backend
  Future<void> eseguiLogoutApi() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      await http.post(
        Uri.parse(ApiConstants.logout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      print('Errore logout API: $e');
    } finally {
      await prefs.remove('auth_token');
      await prefs.remove('user_name');
    }
  }
}