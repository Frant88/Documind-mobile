import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'main.dart';
import 'widgets/document_chat_widget.dart'; // Importa il widget della chat isolato

class DocumentDetailPage extends StatefulWidget {
  final Map<String, dynamic> documento;

  const DocumentDetailPage({super.key, required this.documento});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  bool _isLoading = true;
  String? _localFilePath;
  String _fileContentText = '';
  bool _isTextFile = false;

  static const String _baseUrl = 'http://10.0.2.2:8000/api';
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _caricaDatiIniziali();
  }

  Future<void> _caricaDatiIniziali() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    setState(() {
      _authToken = token;
    });

    await _scaricaEPreparaFile();
  }

  Future<void> _forzaLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    if (mounted) {
      authNotifier.value = false;
    }
  }

  Future<void> _scaricaEPreparaFile() async {
    final token = _authToken;
    final docId = widget.documento['id'];
    final originalName = widget.documento['original_filename'] ?? 'documento.pdf';

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/documents/$docId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 401) {
        await _forzaLogout();
        return;
      }

      if (response.statusCode == 200) {
        if (originalName.endsWith('.txt') || originalName.endsWith('.json') || originalName.endsWith('.md')) {
          setState(() {
            _fileContentText = response.body;
            _isTextFile = true;
            _isLoading = false;
          });
        } else {
          final tempDir = await getTemporaryDirectory();
          final cleanName = originalName.replaceAll(RegExp(r'[^\w\.\-]'), '_');
          final file = File('${tempDir.path}/$cleanName');
          await file.writeAsBytes(response.bodyBytes);

          setState(() {
            _localFilePath = file.path;
            _isTextFile = false;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _fileContentText = 'Errore nel recupero del file dal server.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fileContentText = 'Errore di rete: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _mostraQrCondivisione() async {
    final token = _authToken;
    final docId = widget.documento['id'];

    String shareUrl = 'http://10.0.2.2:8000/api/documents/share/$docId';

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/documents/$docId/generate-qr'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 401) {
        await _forzaLogout();
        return;
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        String? apiSignedUrl = decoded['share_url'] ?? decoded['url'] ?? decoded['signed_url'];
        
        if (apiSignedUrl != null) {
          shareUrl = apiSignedUrl.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2');
        }
      }
    } catch (e) {
      print('Fallback QR attivato per timeout/errore di rete: $e');
    }

    if (!mounted) return;
    _apriDialogQr(shareUrl);
  }

  void _apriDialogQr(String urlCondivisione) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: const Color(0xFF38E54D).withOpacity(0.4)),
        ),
        title: const Text(
          'QR CODE SICURO',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF38E54D), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scansiona questo QR per accedere alla rotta protetta e firmata:',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                width: 200,
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: urlCondivisione,
                  version: QrVersions.auto,
                  size: 176.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                urlCondivisione,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38E54D),
                foregroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('CHIUDI', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titolo = widget.documento['title'] ?? 'Dettaglio Documento';
    final nomeFile = widget.documento['original_filename'] ?? '';
    final docId = widget.documento['id'];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E1B4B),
            Color(0xFF090D16),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.05),
          iconTheme: const IconThemeData(color: Color(0xFF38E54D)),
          title: Text(
            titolo,
            style: const TextStyle(color: Color(0xFF38E54D), fontSize: 15, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_2, color: Color(0xFF38E54D)),
              tooltip: 'Genera QR Sicuro',
              onPressed: _mostraQrCondivisione,
            ),
          ],
        ),
        body: Column(
          children: [
            // HEADER DOCUMENTO CON PULSANTE QR INTEGRATO
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38E54D).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, color: Color(0xFF38E54D), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VISUALIZZAZIONE DOCUMENTO',
                          style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nomeFile,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38E54D).withOpacity(0.15),
                      foregroundColor: const Color(0xFF38E54D),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFF38E54D)),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _mostraQrCondivisione,
                    icon: const Icon(Icons.qr_code, size: 16),
                    label: const Text('SHARE QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),

            // VISUALIZZATORE DOCUMENTO INTEGRATO (PDF o TESTO)
            Expanded(
              flex: 5,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF38E54D)))
                      : _isTextFile
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SingleChildScrollView(
                                child: Text(
                                  _fileContentText,
                                  style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13, height: 1.4),
                                ),
                              ),
                            )
                          : _localFilePath != null
                              ? PDFView(
                                  filePath: _localFilePath!,
                                  enableSwipe: true,
                                  swipeHorizontal: false,
                                  autoSpacing: true,
                                  pageSnap: true,
                                  onError: (error) {
                                    print('Errore rendering PDF: $error');
                                  },
                                  onPageError: (page, error) {
                                    print('Errore pagina $page: $error');
                                  },
                                )
                              : const Center(
                                  child: Text('Impossibile caricare il file.', style: TextStyle(color: Colors.white54)),
                                ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // SEZIONE CHAT IA INTEGRATA CON IL WIDGET DEDICATO
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: _authToken == null
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF38E54D)))
                    : DocumentChatWidget(
                        documentId: docId,
                        baseUrl: _baseUrl,
                        token: _authToken!,
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}