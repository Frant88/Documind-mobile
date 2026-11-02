import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';
import 'document_detail_page.dart';
import 'widgets/app_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _nomeUtente = 'Utente';
  List<dynamic> _documenti = [];
  bool _isLoadingDocs = true;
  bool _isLoggingOut = false;

  static const String _baseUrl = 'http://10.0.2.2:8000/api';

  @override
  void initState() {
    super.initState();
    _caricaDatiUtenteEElenchi();
  }

  Future<void> _caricaDatiUtenteEElenchi() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _nomeUtente = prefs.getString('user_name') ?? 'Utente';
    });
    await _fetchDocumenti();
  }

  Future<void> _forzaLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_name');
    if (mounted) {
      authNotifier.value = false;
    }
  }

  Future<void> _fetchDocumenti() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/documents'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 401) {
        await _forzaLogout();
        return;
      }

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        List<dynamic> lista = [];
        if (decodedData is Map && decodedData['data'] is List) {
          lista = decodedData['data'];
        } else if (decodedData is List) {
          lista = decodedData;
        }

        setState(() {
          _documenti = lista;
          _isLoadingDocs = false;
        });
      } else {
        setState(() => _isLoadingDocs = false);
      }
    } catch (e) {
      if (!mounted) return;
      print('Errore caricamento documenti: $e');
      setState(() => _isLoadingDocs = false);
    }
  }

  Future<void> _eseguiLogoutApi() async {
    setState(() => _isLoggingOut = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    try {
      await http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print('Errore logout: $e');
    } finally {
      await _forzaLogout();
    }
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
          elevation: 0,
          backgroundColor: Colors.white.withOpacity(0.05),
          iconTheme: const IconThemeData(color: Color(0xFF38E54D)),
          title: Text(
            'WELCOME, $_nomeUtente'.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF38E54D),
              letterSpacing: 1.2,
              fontSize: 15,
            ),
          ),
          centerTitle: true,
          actions: [
            _isLoggingOut
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Color(0xFF38E54D), strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.power_settings_new, color: Color(0xFFFF6B6B), size: 22),
                    tooltip: 'Esci',
                    onPressed: _eseguiLogoutApi,
                  ),
          ],
        ),

        // MENU LATERALE RICHIAMATO DAL COMPONENTE
        drawer: const AppDrawer(currentPage: 'home'),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ARCHIVIO DOCUMENTI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF38E54D), size: 20),
                    tooltip: 'Aggiorna',
                    onPressed: () {
                      setState(() => _isLoadingDocs = true);
                      _fetchDocumenti();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoadingDocs
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF38E54D)))
                  : _documenti.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_outlined, size: 56, color: Colors.white24),
                              const SizedBox(height: 12),
                              const Text(
                                'Nessun file trovato nell\'archivio.',
                                style: TextStyle(fontSize: 14, color: Colors.white54),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _documenti.length,
                          itemBuilder: (context, index) {
                            final doc = _documenti[index];
                            
                            final String titoloDoc = doc['title'] ?? doc['original_filename'] ?? 'Documento';
                            final String sottotitoloDoc = doc['original_filename'] ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF38E54D).withOpacity(0.25)),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF38E54D).withOpacity(0.03),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38E54D).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF38E54D), size: 22),
                                ),
                                title: Text(
                                  titoloDoc,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: Colors.white,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    sottotitoloDoc,
                                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                                  ),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF38E54D)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DocumentDetailPage(documento: doc),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: const Color(0xFF38E54D),
          foregroundColor: const Color(0xFF0F172A),
          elevation: 6,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Upload file in arrivo...')),
            );
          },
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('CARICA FILE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
        ),
      ),
    );
  }
}