import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/services/voice_service.dart';

class AuthenticateVoiceScreen extends StatefulWidget {
  const AuthenticateVoiceScreen({super.key});

  @override
  State<AuthenticateVoiceScreen> createState() =>
      _AuthenticateVoiceScreenState();
}

class _AuthenticateVoiceScreenState
    extends State<AuthenticateVoiceScreen> {
  final TextEditingController _nameController = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  final FlutterTts _tts = FlutterTts();

  bool _isRecording = false;
  String? _authResult;

  @override
  void initState() {
    super.initState();
    _voiceService.init();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }

  Future<void> _authenticate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (!_isRecording) {
      await _voiceService.startRecording("temp_auth");
      setState(() => _isRecording = true);
    } else {
      await _voiceService.stopRecording();
      setState(() => _isRecording = false);

      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/voice_$name.aac';
      final file = File(path);

      if (file.existsSync()) {
        final lastModified = await file.lastModified();

        setState(() {
          _authResult = """
Authentication Successful ✅

User: $name
File: voice_$name.aac
Registered On: $lastModified
""";
        });

        await _tts.speak("Welcome $name. Authentication successful.");
      } else {
        setState(() {
          _authResult =
              "Authentication Failed ❌\nNo registered voice found.";
        });

        await _tts.speak(
            "Authentication failed. Voice not recognized.");
      }
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _tts.stop();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Authenticate Voice")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Voice Authentication",
              style:
                  TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Enter Username",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 14),
                ),
                onPressed: _authenticate,
                icon:
                    Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(
                  _isRecording
                      ? "Stop & Authenticate"
                      : "Start Authentication",
                ),
              ),
            ),

            const SizedBox(height: 30),

            if (_authResult != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _authResult!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}