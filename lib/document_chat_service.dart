import 'dart:convert';
import 'package:http/http.dart' as http;

class DocumentChatService {
  final String baseUrl;
  final String token;

  DocumentChatService({required this.baseUrl, required this.token});

  Future<List> fetchHistory(int documentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/documents/$documentId/chat/history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List.from(data['messages']);
    } else {
      throw Exception('Errore nel caricamento della cronologia');
    }
  }

  Future<String> sendMessage(int documentId, String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/documents/$documentId/chat'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'message': message}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? data['message'] ?? 'Risposta ricevuta';
    } else {
      throw Exception("Errore nell'invio del messaggio");
    }
  }
}