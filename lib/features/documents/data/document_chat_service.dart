import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class DocumentChatService {
  
  // Recupera la cronologia dei messaggi dal backend
  Future<List<dynamic>> fetchHistory(int documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.get(
      Uri.parse(ApiConstants.documentChatHistory(documentId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['messages'] ?? [];
    } else {
      throw Exception('Errore nel recupero della cronologia chat');
    }
  }

  // Invia un messaggio all'assistente IA
  Future<String> sendMessage(int documentId, String message) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    final response = await http.post(
      Uri.parse(ApiConstants.documentChatSend(documentId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? data['content'] ?? 'Risposta non ricevuta';
    } else {
      throw Exception('Errore durante l\'invio del messaggio');
    }
  }
}