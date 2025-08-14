import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';

// Твои виджеты сообщения и ввода
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final List<ChatMessage> messages;
  final int index;

  const _MessageBubble({
    required this.message,
    required this.messages,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF1A73E8)
              : const Color(0xFF424242),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.cleanContent,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }
}

class _MessageInput extends StatefulWidget {
  final void Function(String) onSubmitted;
  const _MessageInput({required this.onSubmitted});

  @override
  State<_MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<_MessageInput> {
  final _controller = TextEditingController();
  bool _isComposing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    _controller.clear();
    setState(() => _isComposing = false);
    widget.onSubmitted(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (text) =>
                  setState(() => _isComposing = text.trim().isNotEmpty),
              onSubmitted: _isComposing ? _handleSubmitted : null,
              decoration: const InputDecoration(
                hintText: 'Введите сообщение...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 13),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              ),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, size: 20),
            color: _isComposing ? Colors.blue : Colors.grey,
            onPressed:
                _isComposing ? () => _handleSubmitted(_controller.text) : null,
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        title: const Text('Чат'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessagesList(context)),
          _MessageInput(
            onSubmitted: (text) {
              if (text.trim().isNotEmpty) {
                context.read<ChatProvider>().sendMessage(text);
              }
            },
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (_, chatProvider, __) => ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: chatProvider.messages.length,
        itemBuilder: (_, i) => _MessageBubble(
          message: chatProvider.messages[i],
          messages: chatProvider.messages,
          index: i,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      color: const Color(0xFF262626),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            icon: const Icon(Icons.analytics),
            label: const Text('Статистика'),
            onPressed: () => Navigator.pushNamed(context, '/stats'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.show_chart),
            label: const Text('График'),
            onPressed: () => Navigator.pushNamed(context, '/chart'),
          ),
        ],
      ),
    );
  }
}
