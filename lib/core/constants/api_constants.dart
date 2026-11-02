class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Autenticazione
  static const String login = '$baseUrl/login';
  static const String logout = '$baseUrl/logout';

  // Documenti
  static const String documents = '$baseUrl/documents';

  // Metodi dinamici per singoli documenti (ID variabile)
  static String documentDetail(int id) => '$baseUrl/documents/$id';
  static String documentGenerateQr(int id) => '$baseUrl/documents/$id/generate-qr';
  static String documentShare(int id) => '$baseUrl/documents/share/$id';

  // --- Rotte Chat IA per singolo documento ---
  static String documentChatHistory(int id) => '$baseUrl/documents/$id/chat/history';
  static String documentChatSend(int id) => '$baseUrl/documents/$id/chat';

  // Rotta per il caricamento documenti
  static const String documentUpload = '$baseUrl/documents/upload';

  // ---  ENDPOINT PROFILO ---
  static const String userProfile = '$baseUrl/user/profile';
}