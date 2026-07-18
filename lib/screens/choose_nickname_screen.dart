import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';

class ChooseNicknameScreen extends StatefulWidget {
  const ChooseNicknameScreen({super.key});

  @override
  State<ChooseNicknameScreen> createState() => _ChooseNicknameScreenState();
}

class _ChooseNicknameScreenState extends State<ChooseNicknameScreen> {
  final _service = UserProfileService();
  final _nicknameController = TextEditingController();

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      setState(() => _errorMessage = 'Vul een naam in.');
      return;
    }

    if (nickname.length > 24) {
      setState(() => _errorMessage = 'Maximaal 24 tekens.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    await _service.setNickname(nickname);

    // AuthGate pikt de nieuwe profielstatus automatisch op via de stream —
    // geen handmatige navigatie hier nodig.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1C3F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.badge_outlined, size: 56, color: Colors.white),
              const SizedBox(height: 12),
              const Text(
                'Hoe wil je heten in de community?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dit is de naam die anderen zien — je e-mailadres blijft privé.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 32),

              TextField(
                controller: _nicknameController,
                maxLength: 24,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Naam',
                  labelStyle: const TextStyle(color: Colors.white70),
                  counterStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B1E2B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Doorgaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}