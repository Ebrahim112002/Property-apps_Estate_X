import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../services/supabase_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

/// Simple message model — keeps role, text, timestamp and error state
/// so the UI can style each bubble correctly.
class _ChatMessage {
  final String role; // "user" | "bot"
  final String text;
  final DateTime time;
  final bool isError;

  _ChatMessage({
    required this.role,
    required this.text,
    required this.time,
    this.isError = false,
  });
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final SupabaseService _supabaseService = SupabaseService();
  final FocusNode _inputFocusNode = FocusNode();

  bool _isLoading = false;
  bool _hasText = false;

  late final AnimationController _typingController;

  // 🔑 Hugging Face Configuration
  // NOTE: This token is visible to anyone who inspects the compiled web/app
  // bundle. Before shipping publicly, move this call behind a backend
  // (e.g. a Supabase Edge Function) so the token never reaches the client.
  final String _hfToken = dotenv.env['HF_TOKEN'] ?? '';

  // Hugging Face Inference Providers router (OpenAI-compatible).
  final String _apiUrl = dotenv.env['HF_API_URL'] ?? '';

  //  Upgraded to a much larger, non-gated instruct model.
  // Kimi-K2-Instruct is a ~1T-parameter MoE model with strong instruction
  // following and tool-use quality — a solid step up from Llama-3.3-70B.
  // Other strong non-gated alternatives you can swap in:
  //   "openai/gpt-oss-120b"
  //   "deepseek-ai/DeepSeek-V3.2"
  //   "zai-org/GLM-4.6"
  // Avoid "-Thinking"/reasoning variants here unless you also parse and
  // strip their <think>...</think> reasoning blocks from the reply.
  final String _model = dotenv.env['HF_MODEL'] ?? '';

  // 💡 Default Suggestion Questions
  final List<String> _defaultQuestions = [
    "What properties are available right now?",
    "Show me properties with active bidding status.",
    "Are there any properties available in premium locations?",
    "What is the price range of listed properties?",
  ];

  @override
  void initState() {
    super.initState();
    debugPrint('HF_TOKEN loaded: $_hfToken');
    debugPrint('HF_API_URL loaded: $_apiUrl');
    debugPrint('HF_MODEL loaded: $_model');
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          role: "user",
          text: userMessage.trim(),
          time: DateTime.now(),
        ),
      );
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      String databaseContext = "No custom property data found in database.";

      try {
        // Only real columns — 'status' does not exist on `properties`.
        final List<dynamic> properties = await _supabaseService.supabaseClient
            .from('properties')
            .select('title, price, location, property_type');

        List<dynamic> bidProperties = [];
        try {
          bidProperties = await _supabaseService.supabaseClient
              .from('bid_properties')
              .select('title, price, location, status');
        } catch (bidErr) {
          debugPrint("Bid Properties Fetch Error: $bidErr");
        }

        final Map<String, dynamic> combinedContext = {
          "properties": properties,
          "bid_properties": bidProperties,
        };

        if (properties.isNotEmpty || bidProperties.isNotEmpty) {
          databaseContext = jsonEncode(combinedContext);
        }
      } catch (dbError) {
        debugPrint("Supabase Context Fetch Error: $dbError");
        databaseContext = "Error fetching properties context from database.";
      }

      // ✅ Expanded guidelines: tone, formatting, scope, and edge cases.
      final String systemPrompt =
          """
You are "EstateX AI", the official real estate assistant for the EstateX platform.
Your job is to help users discover, compare, and understand properties using ONLY
the real-time database context provided below. Never invent data that isn't here.

DATABASE CONTEXT (JSON):
$databaseContext

RESPONSE GUIDELINES:
1. Grounding: Base every factual claim (price, location, type, bidding status) strictly
   on the JSON context above. Never invent listings, prices, or locations.
2. Missing data: If a requested field or filter isn't present in the context, say so
   plainly and suggest a close alternative from the available data if one exists.
3. Formatting: When listing multiple properties, use short bullet points with the
   title, location, and price. Format prices with thousands separators (e.g. 1,250,000).
   Keep paragraphs short; prefer scannable structure over dense blocks of text.
4. Tone: Be warm, professional, and concise — like a knowledgeable real estate agent,
   not a generic chatbot. Avoid filler phrases like "As an AI language model...".
5. Scope: Only discuss EstateX properties, pricing, locations, and bidding status.
   If asked something unrelated (general chit-chat, other companies, coding, etc.),
   politely redirect the user back to property-related help.
6. Bidding: If the user asks about "active bidding", check the bid_properties data
   specifically, and clarify the difference between fixed-price and bidding listings
   if both types are relevant to their question.
7. Ambiguity: If a user's request is vague (e.g. "cheap properties"), ask one short
   clarifying question OR show a reasonable default (e.g. the 3 lowest-priced listings)
   rather than refusing to answer.
8. Privacy & safety: Never expose internal database fields that weren't given to you
   (e.g. seller IDs, emails) even if asked directly.
9. No fabrication: If the context is empty or contains an error message, tell the user
   you're temporarily unable to fetch live listings rather than guessing.
10. Language: Always reply in clear, professional English unless the user writes in
    another language, in which case mirror their language.
""";

      final responseApi = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Authorization': 'Bearer $_hfToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              "model": _model,
              "messages": [
                {"role": "system", "content": systemPrompt},
                {"role": "user", "content": userMessage},
              ],
              "max_tokens": 700,
              "temperature": 0.4,
            }),
          )
          .timeout(const Duration(seconds: 40));

      if (responseApi.statusCode == 200) {
        final dynamic data = jsonDecode(responseApi.body);
        String botReply = "";

        try {
          final choices = data['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            botReply = choices[0]['message']?['content'] ?? "";
          }
        } catch (parseErr) {
          debugPrint("Response parse error: $parseErr");
        }

        botReply = botReply.trim();

        if (botReply.isEmpty) {
          botReply =
              "I couldn't generate a response for that. Could you try rephrasing your question?";
        }

        setState(() {
          _messages.add(
            _ChatMessage(role: "bot", text: botReply, time: DateTime.now()),
          );
        });
      } else {
        String errorMessage =
            "Sorry, I'm having trouble generating a response right now.";
        try {
          final dynamic errorData = jsonDecode(responseApi.body);
          if (errorData is Map && errorData['error'] != null) {
            final errText = errorData['error'].toString();
            if (errText.contains('loading')) {
              errorMessage =
                  "The AI model is warming up on the server. Please try again in a few seconds.";
            } else if (errText.toLowerCase().contains('permission')) {
              errorMessage =
                  "AI access isn't configured correctly (permission issue). Please contact support.";
            } else {
              errorMessage = "AI Error: $errText";
            }
          }
        } catch (_) {
          errorMessage =
              "AI Error (${responseApi.statusCode}): ${responseApi.body}";
        }

        setState(() {
          _messages.add(
            _ChatMessage(
              role: "bot",
              text: errorMessage,
              time: DateTime.now(),
              isError: true,
            ),
          );
        });
      }
    } catch (e, stackTrace) {
      debugPrint("Chatbot Execution Failure: $e");
      debugPrint("Stacktrace: $stackTrace");

      setState(() {
        _messages.add(
          _ChatMessage(
            role: "bot",
            text:
                "Failed to connect to the AI server. Please check your internet connection and try again.",
            time: DateTime.now(),
            isError: true,
          ),
        );
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 18,
                      ),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isLoading) {
                          return _buildTypingBubble();
                        }
                        final message = _messages[index];
                        return _buildChatBubble(message);
                      },
                    ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 12,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apartment_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "EstateX AI Assistant",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "Online · Property Assistant",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (_messages.isNotEmpty)
          IconButton(
            tooltip: "Clear chat",
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => setState(() => _messages.clear()),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Welcome to EstateX AI Assistant",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Ask about verified listings, pricing, locations, or active bidding — I'll answer using live data from EstateX.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _defaultQuestions.map((question) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _sendMessage(question),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                question,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isUser, {bool isError = false}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUser
            ? AppColors.primary
            : (isError ? Colors.red[400] : AppColors.primary.withOpacity(0.12)),
      ),
      child: Icon(
        isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
        size: 16,
        color: isUser || isError ? Colors.white : AppColors.primary,
      ),
    );
  }

  Widget _buildChatBubble(_ChatMessage message) {
    final isUser = message.role == "user";
    final isError = message.isError;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(false, isError: isError),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : (isError ? Colors.red[50] : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isError
                        ? Border.all(color: Colors.red[200]!, width: 1)
                        : null,
                    boxShadow: isUser
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: SelectableText(
                    message.text,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : (isError ? Colors.red[700] : Colors.black87),
                      fontSize: 14.5,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _formatTime(message.time),
                    style: TextStyle(fontSize: 10.5, color: Colors.grey[400]),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[const SizedBox(width: 8), _buildAvatar(true)],
        ],
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar(false),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = (_typingController.value + (i * 0.2)) % 1.0;
                    final scale =
                        0.6 + (0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0));
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _inputFocusNode,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                enabled: !_isLoading,
                onSubmitted: (value) => _sendMessage(value),
                decoration: InputDecoration(
                  hintText: "Ask about properties or locations...",
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF1F3F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _isLoading
                  ? null
                  : () => _sendMessage(_messageController.text),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (_hasText && !_isLoading)
                      ? AppColors.primary
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
