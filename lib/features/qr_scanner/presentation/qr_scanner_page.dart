import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../data/qr_scanner_service.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final QrScannerService _scannerService = QrScannerService();
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
        await _elaboraCodiceQr(rawValue);
        break;
      }
    }
  }

  Future<void> _elaboraCodiceQr(String urlCondivisione) async {
    final result = await _scannerService.scaricaFileDaQr(urlCondivisione);

    if (!mounted) return;

    if (result['success'] == true) {
      _mostraDialogSuccesso(result['filePath']);
    } else {
      _mostraErrore(result['message'] ?? 'Errore sconosciuto');
    }
  }

  void _mostraDialogSuccesso(String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
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
          'Il file è stato salvato correttamente:\n$filePath',
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