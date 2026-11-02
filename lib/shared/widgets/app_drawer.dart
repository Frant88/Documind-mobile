import 'package:flutter/material.dart';
import '../../features/qr_scanner/presentation/qr_scanner_page.dart';

class AppDrawer extends StatelessWidget {
  final String currentPage; // Identifica la pagina corrente: 'home', 'qr_scanner', etc.

  const AppDrawer({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header futurista coordinato con l'app
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF38E54D).withOpacity(0.2),
                ),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_shared, color: Color(0xFF38E54D), size: 36),
                SizedBox(height: 12),
                Text(
                  'DOCUMIND',
                  style: TextStyle(
                    color: Color(0xFF38E54D),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Gestione Documentale Sicura',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),

          // --- VOCE: HOME ---
          _buildMenuItem(
            context: context,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            title: 'Home',
            isActive: currentPage == 'home',
            onTap: () {
              Navigator.pop(context); // Chiude il drawer
              if (currentPage != 'home') {
                // Torna alla Home pulendo le rotte sopra
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),

          // --- VOCE: LETTURA QR CODE ---
          _buildMenuItem(
            context: context,
            icon: Icons.qr_code_scanner_outlined,
            activeIcon: Icons.qr_code_scanner,
            title: 'Lettura QR Code',
            isActive: currentPage == 'qr_scanner',
            onTap: () {
              Navigator.pop(context); // Chiude il drawer
              if (currentPage != 'qr_scanner') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QrScannerPage(),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Helper widget per costruire le voci del menu con la voce attiva in risalto
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    if (isActive) {
      // Stile per la voce ATTIVA (In risalto con bordo e sfondo verde neon)
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF38E54D).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF38E54D).withOpacity(0.4)),
        ),
        child: ListTile(
          leading: Icon(activeIcon, color: const Color(0xFF38E54D)),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF38E54D),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Color(0xFF38E54D),
            size: 18,
          ),
          onTap: onTap,
        ),
      );
    }

    // Stile per la voce NON ATTIVA
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}