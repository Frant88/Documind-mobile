import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class DocumentChatService {
  final String token;

  DocumentChatService({required this.token});

  /// Recupera la cronologia dei messaggi della chat per un documento specifico
  Future<List> fetchHistory(int documentId) async {
    final response = await http.get(
      Uri.parse(ApiConstants.documentChatHistory(documentId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List.from(data['messages'] ?? []);
    } else {
      throw Exception('Errore nel caricamento della cronologia');
    }
  }

  /// Invia un messaggio all'IA associata al documento
  Future<String> sendMessage(int documentId, String message) async {
    final response = await http.post(
      Uri.parse(ApiConstants.documentChatSend(documentId)),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'message': message}),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? data['message'] ?? 'Risposta ricevuta';
    } else {
      throw Exception("Errore nell'invio del messaggio");
    }
  }
}