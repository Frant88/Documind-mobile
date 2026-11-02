import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QrScannerService {
  /// Scarica e salva il file sul dispositivo partendo dall'URL del QR code
  Future scaricaFileDaQr(String urlCondivisione) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final String endpoint = urlCondivisione
          .replaceAll('127.0.0.1', '10.0.2.2')
          .replaceAll('localhost', '10.0.2.2');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/documento_condiviso_$timestamp.pdf');
        
        await file.writeAsBytes(response.bodyBytes);

        return {
          'success': true,
          'filePath': file.path,
        };
      } else {
        return {
          'success': false,
          'message': 'Errore dal server: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Errore di connessione o timeout: $e',
      };
    }
  }
}