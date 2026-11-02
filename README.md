# 📂 DocuMind Mobile

> Un'applicazione mobile professionale, sicura e integrata con l'intelligenza artificiale per la gestione e l'interazione avanzata con i documenti, sviluppata con Flutter e basata su un'architettura pulita Feature-First.

---

## 🚀 Panoramica del Progetto

**DocuMind Mobile** nasce come soluzione enterprise per la gestione documentale protetta. L'applicazione consente agli utenti di autenticarsi in modo sicuro, consultare archivi di file (PDF e documenti di testo), interagire tramite una chat IA contestuale integrata per ogni documento, e condividere file in sicurezza tramite QR code crittografati e firmati.

---

## 🏛️ Architettura e Pattern di Progetto

Il progetto adotta rigorosamente una **Feature-First Clean Architecture**, separando nettamente i livelli di presentazione (UI) dalla logica di business e dai servizi di rete. Questo garantisce massima scalabilità, manutenibilità e testabilità del codice.

```text
lib/
├── core/
│   ├── constants/       # Endpoint API centralizzati e configurazioni globali
│   └── network/         # Configurazione del client HTTP e gestione delle richieste
├── features/
│   ├── auth/            # Modulo di autenticazione (Login, AuthService)
│   ├── documents/       # Gestione documenti, dettagli, visualizzazione e chat service
│   └── qr_scanner/      # Lettore QR Code sicuro e downloader di file protetti
└── shared/
    └── widgets/         # Widget globali riutilizzabili (es. AppDrawer)

    🛠️ Stack Tecnologico e Librerie
Framework: Flutter (Dart)

State Management & Navigazione: StatefulWidgets, Material Navigation, ValueNotifier per la gestione reattiva dello stato di autenticazione.

Networking & Sicurezza: Pacchetto http, SharedPreferences per la persistenza sicura dei token di sessione.

Gestione File & Media: path_provider, flutter_pdfview per il rendering nativo dei PDF.

Intelligenza Artificiale: Servizi di chat contestuale integrati (DocumentChatService).

Sicurezza & QR: mobile_scanner, qr_flutter per la generazione e la scansione di URL firmati temporanei.

🔗 Integrazione Backend (Repository Privata)
L'applicazione comunica con un robusto servizio backend sviluppato in Laravel PHP 8.x (ospitato in una repository privata separata).

Caratteristiche principali del Backend integrate:
Autenticazione API: Autenticazione stateless basata su token tramite Laravel Sanctum.

Storage e Isolamento: Archiviazione dei file isolata per utente con generazione di URL temporanei firmati.

Assistente IA Documentale: Endpoint dedicati alla gestione della chat contestuale basata sui payload/embedding dei documenti.

Rotte QR Crittografate: Generazione di rotte protette (/api/documents/share/{id}) accessibili tramite la scansione QR dall'app mobile.

⚙️ Configurazione e Avvio
Clona la repository:

git clone [https://github.com/tuo-username/documind-mobile.git](https://github.com/tuo-username/documind-mobile.git)
cd documind-mobile

Installa le dipendenze:
flutter pub get

Configura gli Endpoint API:
Verifica il file lib/core/constants/api_constants.dart e assicurati che il baseUrl punti correttamente al tuo server Laravel (es. http://10.0.2.2:8000/api per l'emulatore Android).

Avvia l'applicazione:
flutter run

💡 Punti di Forza Tecnici (Per Colloqui)
Separazione delle Responsabilità: Nessuna chiamata HTTP o logica di business hardcoded nelle schermate UI; tutto è delegato a servizi dedicati (*Service).

Zero "Magic Strings": Tutte le rotte e gli endpoint sono centralizzati e tipizzati all'interno di ApiConstants.

Robust Error Handling: Gestione centralizzata dei codici di stato HTTP (es. pulizia automatica della sessione e reindirizzamento forzato in caso di 401 Unauthorized).

📄 Licenza
Questo progetto è distribuito sotto licenza MIT. Consulta il file LICENSE per maggiori informazioni.