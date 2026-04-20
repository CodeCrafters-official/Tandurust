import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  /// 🔐 PUT YOUR OPENROUTER KEY HERE (locally only)
  final String apiKey = "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";
  final String apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  late stt.SpeechToText _speech;
  bool _isListening = false;
  final FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // ================= SEND MESSAGE =================

  void _sendMessage() {
    if (_controller.text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": _controller.text});
      _controller.clear();
    });

    _getBotResponse();
  }

  // ================= OPENROUTER API =================

  Future<void> _getBotResponse() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "https://radha.app",
          "X-Title": "RADHA Assistant"
        },
        body: jsonEncode({
          "model": "openai/gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
              "You are RADHA, a cheerful friendly personal assistant. Respond warmly and casually."
            },
            ..._messages.map((m) => {
              "role": m["role"] == "bot" ? "assistant" : m["role"],
              "content": m["content"]
            })
          ],
          "temperature": 0.7
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botMessage = data['choices'][0]['message']['content'];

        setState(() {
          _messages.add({"role": "bot", "content": botMessage});
        });
      } else {
        setState(() {
          _messages.add({
            "role": "bot",
            "content": "API Error ${response.statusCode}\n${response.body}"
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"role": "bot", "content": "Error: $e"});
      });
    }

    setState(() => _isLoading = false);
  }

  // ================= SPEECH TO TEXT =================

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(onResult: (val) {
          setState(() => _controller.text = val.recognizedWords);
        });
      }
    } else {
      _speech.stop();
      setState(() => _isListening = false);
      _sendMessage();
    }
  }

  // ================= TEXT TO SPEECH =================

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.speak(text);
  }

  // ================= UI =================

  Widget _bubble(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? Colors.teal.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(msg['content'] ?? "")),
            if (!isUser)
              IconButton(
                icon: Icon(Icons.volume_up),
                onPressed: () => _speak(msg['content'] ?? ""),
              )
          ],
        ),
      ),
    );
  }

  // ================= MAIN UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("RADHA Assistant")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _bubble(_messages[index]),
            ),
          ),
          if (_isLoading) CircularProgressIndicator(),
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                    InputDecoration(hintText: "Ask me anything..."),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(icon: Icon(Icons.mic), onPressed: _listen),
                IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}
