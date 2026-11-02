import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class AuthService {
  Future login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        final token = data['token'];
        String userName = 'Utente';
        
        if (data['user'] != null && data['user']['name'] != null) {
          userName = data['user']['name'].toString();
        }

        // Salva token e nome su SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token.toString());
        await prefs.setString('user_name', userName);

        return {
          'success': true,
          'message': data['message'] ?? 'Login effettuato con successo!'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Credenziali non valide'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore di connessione al server: $e'
      };
    }
  }
}