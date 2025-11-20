import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'services/vector_store.dart';
import 'services/enhanced_groq_handler.dart';

class ProfessionalBot extends StatefulWidget {
  const ProfessionalBot({super.key});

  @override
  State<ProfessionalBot> createState() => _ProfessionalBotState();
}

class _ProfessionalBotState extends State<ProfessionalBot> {
  bool _isChatOpen = false;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  // Enhanced handler
  late EnhancedGroqHandler _chatHandler;
  late VectorStore _vectorStore;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      _vectorStore = VectorStore();
      await _vectorStore.loadQAFromAssets();
      _chatHandler = EnhancedGroqHandler(
        vectorStore: _vectorStore,
        flaskApiUrl: 'http://YOUR DEVICE IP:5000/chat', // Your Flask URL
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing chat: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (!_isInitialized) return;

    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({'text': message, 'isUser': true, 'time': DateTime.now()});
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await _chatHandler.getResponse(message);
      setState(() {
        _messages.add({
          'text': response,
          'isUser': false,
          'time': DateTime.now(),
        });
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'text':
              "🌟 MAXIM Assistant\n\nI specialize in:\n• Crane operations\n• Safety procedures\n• Equipment monitoring\n• Load calculations\n• Vibration analysis\n• Temperature monitoring\n\nAsk me anything about CraneIQ!",
          'isUser': false,
          'time': DateTime.now(),
        });
        _isLoading = false;
      });
    }

    _scrollToBottom();
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

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  // KEEP ALL YOUR EXISTING UI CODE BELOW - IT STAYS EXACTLY THE SAME
  // _buildMessageBubble, _buildTypingIndicator, _formatTime, etc.
  // JUST REPLACE THE ABOVE LOGIC

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Stack(
      children: [
        Positioned(
          bottom: 24,
          right: 24,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isChatOpen = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),

        if (_isChatOpen)
          Positioned(
            bottom: 24,
            right: 24,
            child: Container(
              width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 450,
              height: isMobile
                  ? MediaQuery.of(context).size.height * 0.75
                  : 600,
              constraints: const BoxConstraints(
                maxWidth: 500,
                maxHeight: 700,
                minHeight: 400,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: const Color(0xFFe2e8f0), width: 1.5),
              ),
              child: Column(
                children: [
                  // HEADER - unchanged
                  Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            color: Color(0xFF667eea),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'MAXIM Assistant',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: _clearChat,
                          tooltip: 'Clear conversation',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _isChatOpen = false;
                            });
                          },
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                  ),

                  // MESSAGES - unchanged
                  Expanded(
                    child: Container(
                      color: const Color(0xFFf8fafc),
                      child: _messages.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.smart_toy_outlined,
                                      color: Color(0xFF667eea),
                                      size: 56,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'MAXIM Assistant',
                                      style: TextStyle(
                                        color: Color(0xFF667eea),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Powered by Groq AI\nAsk me anything about crane operations\nor any other topic',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF64748b),
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(20),
                              itemCount:
                                  _messages.length + (_isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _messages.length && _isLoading) {
                                  return _buildTypingIndicator();
                                }
                                final message = _messages[index];
                                return _buildMessageBubble(message);
                              },
                            ),
                    ),
                  ),

                  // INPUT - unchanged
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFFe2e8f0),
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFf8fafc),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: const Color(0xFFcbd5e1),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                hintText: 'Ask anything...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                hintStyle: TextStyle(
                                  color: Color(0xFF94a3b8),
                                  fontSize: 15,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667eea).withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                            onPressed: _isLoading ? null : _sendMessage,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // KEEP ALL YOUR EXISTING UI WIDGET METHODS HERE
  Widget _buildMessageBubble(Map<String, dynamic> message) {
    // Your existing _buildMessageBubble code
    final isUser = message['isUser'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          if (!isUser) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF667eea) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isUser
                          ? const Radius.circular(18)
                          : const Radius.circular(6),
                      bottomRight: isUser
                          ? const Radius.circular(6)
                          : const Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    message['text'] as String,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF1e293b),
                      fontSize: 14.5,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(message['time'] as DateTime),
                  style: const TextStyle(
                    color: Color(0xFF94a3b8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MAXIM is thinking',
                    style: TextStyle(
                      color: const Color(0xFF64748b),
                      fontSize: 14.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        const Color(0xFF667eea),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
