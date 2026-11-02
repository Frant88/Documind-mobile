import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../core/constants/api_constants.dart'; 

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _nomeUtente = 'Caricamento...';
  String _emailUtente = 'Caricamento...';
  String _dataCreazione = 'Caricamento...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileApi();
  }

  Future<void> _fetchProfileApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        await _forzaLogoutLocalmente();
        return;
      }

      // Utilizza la costante centralizzata per l'endpoint del profilo
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/user/profile'), // <-- Usato api_constant
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final userData = decoded['data'] ?? decoded;

        final String nome = userData['name'] ?? 'Utente';
        final String email = userData['email'] ?? 'Non disponibile';
        final String rawDate = userData['created_at'] ?? '';
        
        final String dataFormattata = rawDate.isNotEmpty
            ? (rawDate.contains('T') ? rawDate.split('T')[0] : rawDate)
            : 'Non disponibile';

        // Salva in cache locale per il fallback offline
        await prefs.setString('user_name', nome);
        await prefs.setString('user_email', email);
        await prefs.setString('created_at', rawDate);

        setState(() {
          _nomeUtente = nome;
          _emailUtente = email;
          _dataCreazione = dataFormattata;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await _forzaLogoutLocalmente();
      } else {
        throw Exception('Errore di comunicazione col server');
      }
    } catch (e) {
      // Fallback offline: legge le preferenze locali salvate
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      setState(() {
        _nomeUtente = prefs.getString('user_name') ?? 'Utente';
        _emailUtente = prefs.getString('user_email') ?? 'Non disponibile';
        final rawDate = prefs.getString('created_at');
        _dataCreazione = rawDate != null && rawDate.isNotEmpty
            ? (rawDate.contains('T') ? rawDate.split('T')[0] : rawDate)
            : 'Non disponibile';
        _isLoading = false;
      });
    }
  }

  Future<void> _forzaLogoutLocalmente() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      authNotifier.value = false;
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
          title: const Text(
            'PROFILO UTENTE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF38E54D),
              letterSpacing: 1.2,
              fontSize: 15,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF38E54D), size: 20),
              tooltip: 'Aggiorna',
              onPressed: () {
                setState(() => _isLoading = true);
                _fetchProfileApi();
              },
            ),
          ],
        ),
        drawer: const AppDrawer(currentPage: 'profile'),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF38E54D)))
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF38E54D).withOpacity(0.4), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: const Color(0xFF38E54D).withOpacity(0.15),
                          child: const Icon(Icons.person, size: 50, color: Color(0xFF38E54D)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _nomeUtente,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _emailUtente,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          _buildInfoTile(
                            icon: Icons.badge_outlined,
                            title: 'Nome Utente',
                            value: _nomeUtente,
                          ),
                          Divider(color: Colors.white.withOpacity(0.05), height: 1),
                          _buildInfoTile(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: _emailUtente,
                          ),
                          Divider(color: Colors.white.withOpacity(0.05), height: 1),
                          _buildInfoTile(
                            icon: Icons.calendar_today_outlined,
                            title: 'Account Creato Il',
                            value: _dataCreazione,
                          ),
                          Divider(color: Colors.white.withOpacity(0.05), height: 1),
                          _buildInfoTile(
                            icon: Icons.shield_outlined,
                            title: 'Stato Account',
                            value: 'Attivo',
                            valueColor: const Color(0xFF38E54D),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF38E54D), size: 20),
          const SizedBox(width: 14),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}