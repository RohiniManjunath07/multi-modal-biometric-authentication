import 'package:flutter/material.dart';
import '../../data/services/voice_service.dart';
import 'authenticate_voice_screen.dart';

class RegisterVoiceScreen extends StatefulWidget {
  const RegisterVoiceScreen({super.key});

  @override
  State<RegisterVoiceScreen> createState() => _RegisterVoiceScreenState();
}

class _RegisterVoiceScreenState extends State<RegisterVoiceScreen> {
  final TextEditingController _nameController = TextEditingController();
  final VoiceService _voiceService = VoiceService();

  bool _isRecording = false;
  bool _showConfirm = false;

  @override
  void initState() {
    super.initState();
    _voiceService.init();
  }

  Future<void> _toggleRecording() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    if (!_isRecording) {
      await _voiceService.startRecording(name);
      setState(() => _isRecording = true);
    } else {
      await _voiceService.stopRecording();
      setState(() {
        _isRecording = false;
        _showConfirm = true;
      });
    }
  }

  void _confirmSubmission() {
    setState(() => _showConfirm = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Voice Registered Successfully")),
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Voice")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration:
                  const InputDecoration(labelText: "Enter Username"),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: _toggleRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(
                  _isRecording ? "Stop Recording" : "Start Recording"),
            ),

            const SizedBox(height: 20),

            if (_showConfirm)
              ElevatedButton(
                onPressed: _confirmSubmission,
                child: const Text("Confirm & Submit Voice"),
              ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AuthenticateVoiceScreen(),
                  ),
                );
              },
              child: const Text("Go to Authenticate"),
            ),
          ],
        ),
      ),
    );
  }
}