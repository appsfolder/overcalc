import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:showcaseview/showcaseview.dart';
import 'dart:convert';

import 'history_screen.dart';
import '../models/calculator_personality.dart';
import '../services/gemini_service.dart';
import '../widgets/calculator_button.dart';
import '../widgets/spinning_arc_loader.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  bool _isLoading = false;
  final List<Content> _chatHistory = [];
  late CalculatorPersonality _currentPersonality;

  final GeminiService _geminiService = GeminiService();

  final _storage = const FlutterSecureStorage();

  final GlobalKey _menuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _saveState() async {
    final historyJson = jsonEncode(
      _chatHistory.map((c) => {'role': c.role, 'text': c.text}).toList(),
    );
    await _storage.write(key: 'chat_history', value: historyJson);
    await _storage.write(
      key: 'selected_personality',
      value: _currentPersonality.name,
    );
  }

  Future<void> _loadState() async {
    final historyJson = await _storage.read(key: 'chat_history');
    if (historyJson != null) {
      final historyList = jsonDecode(historyJson) as List;
      _chatHistory.clear();
      _chatHistory.addAll(
        historyList.map((j) => Content(j['role'], j['text'])),
      );
    }

    final personalityName = await _storage.read(key: 'selected_personality');
    if (personalityName != null) {
      _currentPersonality = personalities.firstWhere(
        (p) => p.name == personalityName,
        orElse: () => personalities.first,
      );
    } else {
      _currentPersonality = personalities.first;
    }
    setState(() {});
  }

  void _onButtonPressed(String value) {
    HapticFeedback.lightImpact();
    if (_isLoading) return;

    setState(() {
      if (value == 'C') {
        _display = '0';
      } else if (value == '⌫') {
        if (_display.length > 1) {
          _display = _display.substring(0, _display.length - 1);
        } else {
          _display = '0';
        }
      } else if (value == '=') {
        _calculateWithGemini();
      } else {
        if (_display == '0') {
          _display = value;
        } else {
          _display += value;
        }
      }
    });
  }

  Future<void> _calculateWithGemini() async {
    if (_display == '0' || _display.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userRequestText = _display;
      final result = await _geminiService.getResponse(
        _currentPersonality.prompt,
        _chatHistory,
        userRequestText,
      );

      _checkAndShowHint();

      _chatHistory.add(Content('user', userRequestText));
      _chatHistory.add(Content('model', result));

      await _saveState();

      if (_chatHistory.length > 8) {
        _chatHistory.removeRange(0, 2);
      }

      setState(() {
        _display = result;
      });
    } catch (e) {
      setState(() {
        _display = e.toString().contains('API ключ не найден')
            ? 'API ключ не найден'
            : 'Произошла ошибка. Попробуйте еще раз позже';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "OverCalc",
          style: TextStyle(
            fontFamily: 'IBMPlexSans',
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HistoryScreen(chatHistory: _chatHistory),
                ),
              );
            },
          ),

          Showcase.withWidget(
            key: _menuKey,
            container: Container(
              height: 96,
              width: 220,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).dialogTheme.backgroundColor ??
                    const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: const Text(
                'Попробуйте другие личности для калькулятора!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            targetShapeBorder: const CircleBorder(),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'change_personality') {
                  _showPersonalityDialog();
                } else if (value == 'about') {
                  _showAboutDialog();
                } else if (value == 'clear_history') {
                  _resetCalculatorState();
                } else if (value == 'set_api_key') {
                  _showApiKeyDialog();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'change_personality',
                  child: ListTile(
                    leading: const Icon(Icons.psychology_alt),
                    title: const Text(
                      'Сменить личность',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'clear_history',
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text(
                      'Очистить историю',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'set_api_key',
                  child: ListTile(
                    leading: const Icon(Icons.vpn_key_outlined),
                    title: const Text(
                      'Свой API ключ',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'about',
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text(
                      'О приложении',
                      style: TextStyle(
                        fontFamily: 'IBMPlexSans',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.bottomRight,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.only(bottom: 28.0, right: 8.0),
                        child: SpinningArcLoader(size: 48),
                      )
                    : SingleChildScrollView(
                        reverse: true,
                        child: AutoSizeText(
                          _display,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'IBMPlexSans',
                            fontSize: 80,
                            fontWeight: FontWeight.w300,
                          ),
                          minFontSize: 24,
                          maxLines: 5,
                        ),
                      ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                children: [
                  _buildButtonRow(['C', '(', ')', '/']),
                  _buildButtonRow(['7', '8', '9', '×']),
                  _buildButtonRow(['4', '5', '6', '-']),
                  _buildButtonRow(['1', '2', '3', '+']),
                  _buildButtonRow(['⌫', '0', '.', '=']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map((buttonText) {
          return CalculatorButton(
            text: buttonText,
            onPressed: () => _onButtonPressed(buttonText),
            backgroundColor: _getButtonColor(buttonText),
            textColor: _getTextColor(buttonText),
          );
        }).toList(),
      ),
    );
  }

  Color _getButtonColor(String text) {
    if (['/', '×', '-', '+', '='].contains(text)) {
      return Colors.amber.shade700;
    }
    if (['C', '⌫', '(', ')'].contains(text)) {
      return Colors.grey.shade700;
    }
    return Colors.grey.shade800;
  }

  Color _getTextColor(String text) {
    if (['/', '×', '-', '+', '=', 'C', '⌫', '(', ')'].contains(text)) {
      return Colors.white;
    }
    return Colors.white;
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'OverCalc',
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontWeight: FontWeight.w400,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Overengineered Calculator',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Создано на Flutter.',
                  style: const TextStyle(
                    fontFamily: 'IBMPlexSans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final url = Uri.parse(
                      'https://www.rustore.ru/catalog/app/com.appsfolder.overcalc',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.update,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'RuStore',
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSans',
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final url = Uri.parse(
                      'https://github.com/appsfolder/overcalc',
                    );
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.merge,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'source code',
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSans',
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () async {
                    final url = Uri.parse('https://github.com/appsfolder');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.account_circle,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'by appsfolder',
                            style: const TextStyle(
                              fontFamily: 'IBMPlexSans',
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Закрыть'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPersonalityDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Выберите альтер-эго:',
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontWeight: FontWeight.w400,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 8.0,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: personalities.length,
              itemBuilder: (BuildContext context, int index) {
                final personality = personalities[index];
                final bool isSelected = personality == _currentPersonality;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _currentPersonality = personality;
                      _display = '0';
                      _chatHistory.clear();
                      _saveState();
                    });
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(16.0),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.amber.withOpacity(0.15)
                          : Colors.grey.shade800,
                      border: isSelected
                          ? Border.all(color: Colors.amber.shade700, width: 2.0)
                          : null,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Column(
                      children: [
                        Text(
                          personality.name,
                          style: isSelected
                              ? const TextStyle(
                                  fontFamily: 'IBMPlexSans',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                )
                              : const TextStyle(
                                  fontFamily: 'IBMPlexSans',
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          personality.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'IBMPlexSans',
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _resetCalculatorState() {
    setState(() {
      _display = '0';
      _chatHistory.clear();
    });
  }

  void _showApiKeyDialog() async {
    final storage = const FlutterSecureStorage();
    final currentKey = await storage.read(key: 'user_gemini_api_key') ?? '';
    if (!mounted) return;
    final controller = TextEditingController(text: currentKey);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Ваш Gemini API ключ',
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontWeight: FontWeight.w400,
            ),
          ),
          content: TextField(
            style: const TextStyle(
              fontFamily: 'IBMPlexSans',
              fontWeight: FontWeight.w400,
            ),
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Вставьте ключ сюда',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await storage.delete(key: 'user_gemini_api_key');
                Navigator.of(context).pop();
              },
              child: const Text('Удалить'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newKey = controller.text.trim();
                if (newKey.isNotEmpty) {
                  await storage.write(
                    key: 'user_gemini_api_key',
                    value: newKey,
                  );
                } else {
                  await storage.delete(key: 'user_gemini_api_key');
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                'Сохранить',
                style: TextStyle(
                  fontFamily: 'IBMPlexSans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndShowHint() async {
    String? requestCountStr = await _storage.read(key: 'request_count');
    String? hintShownStr = await _storage.read(key: 'personality_hint_shown');
    int requestCount = int.tryParse(requestCountStr ?? '') ?? 0;
    bool hintShown = hintShownStr == 'true';

    if (!hintShown && requestCount >= 1) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        ShowCaseWidget.of(context).startShowCase([_menuKey]);
      }
      await _storage.write(key: 'personality_hint_shown', value: 'true');
    }

    await _storage.write(
      key: 'request_count',
      value: (requestCount + 1).toString(),
    );
  }
}
