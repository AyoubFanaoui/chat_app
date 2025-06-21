import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(ChatApp());

class ChatColors {
  static const Color userMessage = Color(0xFFDCF8C6);
  static const Color botMessage = Color(0xFFECECEC);
  static const Color background = Color(0xFFF0F0F0);
  static const Color appBar = Color(0xFF075E54);
  static const Color icon = Color(0xFF128C7E);
}

// Header stylisé
class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String avatarUrl;

  const ChatHeader({
    Key? key,
    required this.title,
    required this.avatarUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: ChatColors.appBar,
      elevation: 2,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(avatarUrl),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    "En ligne",
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

// Bulle de message
class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final String avatar;

  const MessageBubble({
    required this.text,
    required this.isUser,
    required this.avatar,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final alignment = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final color = isUser ? ChatColors.userMessage : ChatColors.botMessage;

    return Row(
      mainAxisAlignment: alignment,
      children: [
        if (!isUser)
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(avatar),
          ),
        SizedBox(width: 8),
        Container(
          margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          constraints: BoxConstraints(maxWidth: 260),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: isUser ? Radius.circular(16) : Radius.circular(4),
              bottomRight: isUser ? Radius.circular(4) : Radius.circular(16),
            ),
          ),
          child: Text(
            text,
            style: TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
        if (isUser) SizedBox(width: 8),
        if (isUser)
          CircleAvatar(
            radius: 16,
            backgroundColor: ChatColors.icon,
            child: Icon(Icons.person, color: Colors.white, size: 18),
          ),
      ],
    );
  }
}

// Application principale
class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ollama Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: ChatColors.background,
        primaryColor: ChatColors.appBar,
      ),
      home: ChatScreen(),
    );
  }
}

// Écran principal
class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, String>> messages = [];

  Future<void> _sendMessage() async {
    final userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({"sender": "user", "text": userMessage});
      _controller.clear();
    });

    try {
      final res = await http.post(
        Uri.parse("http://localhost:5000/chat"), // Change si besoin
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": userMessage}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          messages.add({"sender": "bot", "text": data["response"]});
        });
      } else {
        setState(() {
          messages.add({
            "sender": "bot",
            "text": "Erreur serveur : ${res.statusCode}"
          });
        });
      }
    } catch (e) {
      setState(() {
        messages.add({"sender": "bot", "text": "Erreur de connexion."});
      });
    }

    Future.delayed(Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatHeader(
        title: "Ollama Chat",
        avatarUrl:
        "https://avatars.githubusercontent.com/u/54929980?s=64&v=4",
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              padding: EdgeInsets.only(top: 12),
              itemBuilder: (context, index) {
                final msg = messages[index];
                return MessageBubble(
                  text: msg["text"] ?? "",
                  isUser: msg["sender"] == "user",
                  avatar:
                  "https://avatars.githubusercontent.com/u/54929980?s=64&v=4",
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "Écris un message...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.grey.shade200,
                        filled: true,
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: ChatColors.icon,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.send),
                      color: Colors.white,
                      onPressed: _sendMessage,
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
}
