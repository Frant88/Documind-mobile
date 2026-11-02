import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../document_chat_service.dart'; // Assicurati che il percorso del service sia corretto

class DocumentChatWidget extends StatefulWidget {
  final int documentId;
  final String baseUrl;
  final String token;

  const DocumentChatWidget({
    Key? key,
    required this.documentId,
    required this.baseUrl,
    required this.token,
  }) : super(key: key);

  @override
  State<DocumentChatWidget> createState() => _DocumentChatWidgetState();
}

class _DocumentChatWidgetState extends State<DocumentChatWidget> {
  late final DocumentChatService _chatService;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List messages = [];
  bool isLoadingHistory = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    _chatService = DocumentChatService(
      baseUrl: widget.baseUrl,
      token: widget.token,
    );
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final fetchedMessages = await _chatService.fetchHistory(widget.documentId);
      setState(() {
        messages = fetchedMessages;
        isLoadingHistory = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => isLoadingHistory = false);
      // Se vuoi un feedback a schermo in caso di errore di rete
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    // Aggiungiamo subito il messaggio dell'utente per reattività grafica immediata
    setState(() {
      messages.add({'role': 'user', 'content': text});
      isSending = true; // Attiva i tre puntini di caricamento dell'IA
    });
    _scrollToBottom();

    try {
      final aiReply = await _chatService.sendMessage(widget.documentId, text);
      setState(() {
        messages.add({'role': 'model', 'content': aiReply});
      });
    } catch (e) {
      // Gestione dell'errore di invio (es. messaggio di sistema o snackbar)
    } finally {
      setState(() {
        isSending = false; // Disattiva i tre puntini in ogni caso
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Area della cronologia dei messaggi
        Expanded(
          child: isLoadingHistory
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Nessun messaggio. Inizia la conversazione!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Se siamo all'ultimo elemento e l'IA sta rispondendo, mostriamo i tre puntini
                        if (index == messages.length && isSending) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 14,
                                  child: Text('AI', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const SpinKitThreeBounce(
                                    color: Colors.grey,
                                    size: 18.0,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final msg = messages[index];
                        final isUser = msg['role'] == 'user';

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            child: Text(
                              msg['content'] ?? '',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Barra di input in basso
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Scrivi un messaggio...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onSubmitted: (_) => _handleSendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blue),
                onPressed: isSending ? null : _handleSendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }
}