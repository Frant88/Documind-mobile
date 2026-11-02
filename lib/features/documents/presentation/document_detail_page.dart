import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart';
import '../../../core/constants/api_constants.dart';
import '../data/document_detail_service.dart';
import '../../../../shared/widgets/document_chat_widget.dart';

class DocumentDetailPage extends StatefulWidget {
  final Map<String, dynamic> documento;

  const DocumentDetailPage({super.key, required this.documento});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  final DocumentDetailService _detailService = DocumentDetailService();

  bool _isLoading = true;
  String? _localFilePath;
  String _fileContentText = '';
  bool _isTextFile = false;
  String? _authToken;

  @override
  void initState() {
    super.initState();
    _caricaDatiIniziali();
  }

  Future<void> _caricaDatiIniziali() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (!mounted) return;
    setState(() {
      _authToken = token;
    });

    if (token != null) {
      await _scaricaEPreparaFile(token);
    }
  }

  Future<void> _forzaLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    if (mounted) {
      authNotifier.value = false;
    }
  }

  Future<void> _scaricaEPreparaFile(String token) async {
    final docId = widget.documento['id'];
    final originalName = widget.documento['original_filename'] ?? 'documento.pdf';

    final result = await _detailService.scaricaDocumento(docId, originalName, token);

    if (!mounted) return;

    if (result['unauthorized'] == true) {
      await _forzaLogout();
      return;
    }

    setState(() {
      _isTextFile = result['isText'] ?? false;
      if (_isTextFile) {
        _fileContentText = result['textContent'] ?? '';
      } else {
        _localFilePath = result['localPath'];
      }
      _isLoading = false;
    });
  }

  Future<void> _mostraQrCondivisione() async {
    if (_authToken == null) return;
    final docId = widget.documento['id'];

    final shareUrl = await _detailService.generaUrlQr(docId, _authToken!);

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
                                  onError: (error) => print('Errore rendering PDF: $error'),
                                  onPageError: (page, error) => print('Errore pagina $page: $error'),
                                )
                              : const Center(
                                  child: Text('Impossibile caricare il file.', style: TextStyle(color: Colors.white54)),
                                ),
                ),
              ),
            ),
            const SizedBox(height: 12),
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