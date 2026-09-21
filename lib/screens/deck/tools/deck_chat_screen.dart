import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/ai_recommendation.dart';
import '../../../models/deck.dart';
import '../../../services/gemini_ai_service.dart';

class DeckChatScreen extends StatefulWidget {
  final Deck deck;

  const DeckChatScreen({super.key, required this.deck});

  @override
  State<DeckChatScreen> createState() => _DeckChatScreenState();
}

class _DeckChatScreenState extends State<DeckChatScreen> {
  static const _uuid = Uuid();
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _quickSuggestions = [
    '¿Cuál es mi condición de victoria principal?',
    '¿Qué carta recomiendas quitar para meter Rhystic Study?',
    '¿Cómo puedo acelerar los primeros 3 turnos?',
    '¿Mi base de tierras está bien balanceada?',
  ];

  @override
  void initState() {
    super.initState();
    // Initial welcome message
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        text:
            '¡Hola! Soy tu Copiloto de IA para "${widget.deck.name}". He cargado las ${widget.deck.totalCards} cartas de tu mazo en mi memoria. ¿En qué aspecto táctico o mejora te gustaría enfocarte?',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage([String? predefinedText]) async {
    final text = (predefinedText ?? _messageController.text).trim();
    if (text.isEmpty || _isTyping) return;

    final userMsg = ChatMessage(id: _uuid.v4(), text: text, isUser: true);
    setState(() {
      _messages.add(userMsg);
      _isTyping = true;
      if (predefinedText == null) _messageController.clear();
    });
    _scrollToBottom();

    try {
      final answer = await GeminiAiService.chatWithDeckAssistant(
        deck: widget.deck,
        history: _messages,
        userMessage: text,
      );

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(id: _uuid.v4(), text: answer, isUser: false));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              id: _uuid.v4(),
              text: 'Hubo un error al procesar tu consulta: $e',
              isUser: false,
            ),
          );
          _isTyping = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Copiloto de Mazo IA', style: TextStyle(fontSize: 16)),
            Text(
              widget.deck.name,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isUser ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                          bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                        ),
                        border: Border.all(
                          color: msg.isUser ? AppColors.primaryLight : AppColors.border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!msg.isUser)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.psychology, size: 14, color: AppColors.foilGold),
                                  SizedBox(width: 4),
                                  Text(
                                    'Copiloto IA',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.foilGold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: msg.isUser ? Colors.white : AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Typing Indicator
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Analizando "${widget.deck.name}"...',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

            // Quick Prompt Chips
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _quickSuggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final prompt = _quickSuggestions[index];
                  return ActionChip(
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                    label: Text(
                      prompt,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    onPressed: _isTyping ? null : () => _sendMessage(prompt),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Message Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: const InputDecoration(
                        hintText: 'Pregunta algo sobre este mazo...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send, size: 20),
                    onPressed: _isTyping ? null : () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
