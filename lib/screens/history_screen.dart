import 'package:flutter/material.dart';
import '../services/gemini_service.dart';

class HistoryScreen extends StatelessWidget {
  final List<Content> chatHistory;

  const HistoryScreen({super.key, required this.chatHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'История вычислений',
          style: TextStyle(
            fontFamily: 'IBMPlexSans',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: chatHistory.isEmpty
          ? const Center(
              child: Text(
                'История пока пуста',
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                final item = chatHistory[index];
                final isUser = item.role == 'user';
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 5.0,
                      horizontal: 8.0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.amber.shade700
                          : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Text(
                      item.text,
                      style: const TextStyle(
                        fontFamily: 'IBMPlexSans',
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
