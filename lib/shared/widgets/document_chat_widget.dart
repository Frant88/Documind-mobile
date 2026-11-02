import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../features/documents/data/document_chat_service.dart';

class DocumentChatWidget extends StatefulWidget {
  final int documentId;

  const DocumentChatWidget({
    Key? key,
    required this.documentId,
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
    // Istanziazione pulita: il service gestisce autonomamente token e ApiConstants
    _chatService = DocumentChatService();
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
    }
  }

  Future<void> _handleSendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    setState(() {
      messages.add({'role': 'user', 'content': text});
      isSending = true;
    });
    _scrollToBottom();

    try {
      final aiReply = await _chatService.sendMessage(widget.documentId, text);
      setState(() {
        messages.add({'role': 'model', 'content': aiReply});
      });
    } catch (e) {
      // Gestione dell'errore di invio
    } finally {
      setState(() {
        isSending = false;
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