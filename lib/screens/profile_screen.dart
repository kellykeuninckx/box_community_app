import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/wall_of_fame_service.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = UserProfileService();
  final _wallOfFameService = WallOfFameService();
  final _nicknameController = TextEditingController();
  final _bodyweightController = TextEditingController();

  bool _isEditingNickname = false;
  bool _isEditingBodyweight = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    _bodyweightController.dispose();
    super.dispose();
  }

  Future<void> _saveNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    setState(() => _isSaving = true);
    await _profileService.setNickname(nickname);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditingNickname = false;
    });
  }

  Future<void> _saveBodyweight(String gender) async {
    final weight = double.tryParse(_bodyweightController.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0) return;

    setState(() => _isSaving = true);
    await _profileService.setWeightClassInfo(gender: gender, bodyweightKg: weight);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditingBodyweight = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profiel'),
        backgroundColor: const Color(0xFF0F1C3F),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _profileService.currentUserProfile,
        builder: (context, snapshot) {
          final profile = snapshot.data;

          if (!_isEditingNickname && profile != null) {
            _nicknameController.text = profile.nickname;
          }
          if (!_isEditingBodyweight && profile?.bodyweightKg != null) {
            _bodyweightController.text = profile!.bodyweightKg!.toStringAsFixed(1);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Naam',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 4),
              if (_isEditingNickname)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nicknameController,
                        maxLength: 24,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      onPressed: _isSaving ? null : _saveNickname,
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile?.nickname ?? '',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () => setState(() => _isEditingNickname = true),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              const Text(
                'E-mailadres',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 4),
              Text(email, style: const TextStyle(fontSize: 14)),

              if (profile?.hasWeightClassInfo == true) ...[
                const SizedBox(height: 20),
                const Text(
                  'Gewichtsklasse-gegevens',
                  style: TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 4),
                Text(
                  'Geslacht: ${profile!.gender == 'M' ? 'Man' : 'Vrouw'}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 6),
                if (_isEditingBodyweight)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bodyweightController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Lichaamsgewicht (kg)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check),
                        onPressed: _isSaving ? null : () => _saveBodyweight(profile.gender!),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${profile.bodyweightKg?.toStringAsFixed(1)} kg',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: () => setState(() => _isEditingBodyweight = true),
                      ),
                    ],
                  ),
                const Text(
                  'Pas dit aan zodra je gewicht verandert — houdt je gewichtsklasse actueel.',
                  style: TextStyle(fontSize: 11, color: Colors.black38),
                ),
              ],

              const SizedBox(height: 20),

              const Text(
                'Reacties gegeven',
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
              const SizedBox(height: 4),
              FutureBuilder<int>(
                future: uid != null ? _wallOfFameService.countReactionsGiven(uid) : Future.value(0),
                builder: (context, countSnapshot) {
                  if (!countSnapshot.hasData) {
                    return const Text('...', style: TextStyle(fontSize: 14));
                  }
                  return Text(
                    '${countSnapshot.data} keer op de Wall of Fame',
                    style: const TextStyle(fontSize: 14),
                  );
                },
              ),

              const SizedBox(height: 32),

              OutlinedButton.icon(
                onPressed: () => AuthService().signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Uitloggen'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8B1E2B),
                  side: const BorderSide(color: Color(0xFF8B1E2B)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}