import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/app_drawer.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetectQr(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        setState(() => _isProcessing = true);
        await _scannerController.stop();
        await _scaricaESalvaFileDaQr(rawValue);
        break;
      }
    }
  }

  Future<void> _scaricaESalvaFileDaQr(String urlCondivisione) async {
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
      ).timeout(const Duration(seconds: 5));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${tempDir.path}/documento_condiviso_$timestamp.pdf');
        
        await file.writeAsBytes(response.bodyBytes);

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: const Color(0xFF38E54D).withOpacity(0.4)),
            ),
            title: const Text(
              'DOCUMENTO SCARICATO',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF38E54D), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Il file è stato salvato correttamente:\n${file.path}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38E54D),
                    foregroundColor: const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _isProcessing = false);
                    _scannerController.start();
                  },
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      } else {
        _mostraErrore('Errore dal server: ${response.statusCode}');
      }
    } catch (e) {
      _mostraErrore('Errore di connessione o timeout: $e');
    }
  }

  void _mostraErrore(String messaggio) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(messaggio), backgroundColor: Colors.redAccent),
    );
    setState(() => _isProcessing = false);
    _scannerController.start();
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text(
            'LETTURA QR CODE',
            style: TextStyle(color: Color(0xFF38E54D), fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1),
          ),
        ),
        drawer: const AppDrawer(currentPage: 'qr_scanner'),
        body: Stack(
          children: [
            MobileScanner(
              controller: _scannerController,
              onDetect: _onDetectQr,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Impossibile avviare la fotocamera: ${error.errorCode}\n(Se usi l\'emulatore, assicurati che supporti la webcam).',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                );
              },
            ),
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF38E54D), width: 2),
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.transparent,
                ),
              ),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF38E54D)),
                ),
              ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Text(
                'Inquadra il QR code per scaricare il documento',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  backgroundColor: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}