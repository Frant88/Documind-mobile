import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/api_constants.dart';

class DocumentDetailService {
  /// Scarica il documento (PDF o Testo) e restituisce il percorso locale o il contenuto
  Future scaricaDocumento(int docId, String originalName, String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.documentDetail(docId)),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 401) {
        return {'unauthorized': true};
      }

      if (response.statusCode == 200) {
        if (originalName.endsWith('.txt') || originalName.endsWith('.json') || originalName.endsWith('.md')) {
          return {
            'unauthorized': false,
            'isText': true,
            'textContent': response.body,
          };
        } else {
          final tempDir = await getTemporaryDirectory();
          final cleanName = originalName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
          final file = File('${tempDir.path}/$cleanName');
          await file.writeAsBytes(response.bodyBytes);

          return {
            'unauthorized': false,
            'isText': false,
            'localPath': file.path,
          };
        }
      }

      return {
        'unauthorized': false,
        'isText': true,
        'textContent': 'Errore nel recupero del file dal server.',
      };
    } catch (e) {
      return {
        'unauthorized': false,
        'isText': true,
        'textContent': 'Errore di rete: $e',
      };
    }
  }

  /// Ottiene la URL firmata per la condivisione tramite QR code
  Future<String> generaUrlQr(int docId, String token) async {
    String fallbackUrl = ApiConstants.documentShare(docId);

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.documentGenerateQr(docId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        String? apiSignedUrl = decoded['share_url'] ?? decoded['url'] ?? decoded['signed_url'];
        
        if (apiSignedUrl != null) {
          return apiSignedUrl.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
        }
      }
    } catch (e) {
      print('Fallback QR attivato: $e');
    }

    return fallbackUrl;
  }
}