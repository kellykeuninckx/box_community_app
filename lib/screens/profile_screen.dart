import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../services/wall_of_fame_service.dart';
import '../models/user_profile.dart';
import '../widgets/logo_pattern_background.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _navy = Color(0xFF0F1C3F);
const _cardColor = Color(0xFF1B2E5C);

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

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Card(
      color: _cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        title: const Text('Profiel'),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      body: Stack(
        children: [
          const LogoPatternBackground(),
          StreamBuilder<UserProfile?>(
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
                  // Header-kaart: avatar-cirkel + naam
                  _sectionCard(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: _red,
                            child: Text(
                              (profile?.nickname.isNotEmpty == true ? profile!.nickname[0] : '?').toUpperCase(),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _isEditingNickname
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _nicknameController,
                                          maxLength: 24,
                                          style: const TextStyle(color: _cream),
                                          decoration: _fieldDecoration('Naam'),
                                        ),
                                      ),
                                      IconButton(
                                        icon: _isSaving
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2, color: _cream),
                                              )
                                            : const Icon(Icons.check, color: _cream),
                                        onPressed: _isSaving ? null : _saveNickname,
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          profile?.nickname ?? '',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _cream),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit, size: 18, color: _cream.withOpacity(0.7)),
                                        onPressed: () => setState(() => _isEditingNickname = true),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Account-kaart
                  _sectionCard(
                    children: [
                      Text('Account', style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.5), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Text('E-mailadres', style: TextStyle(fontSize: 11, color: _cream.withOpacity(0.5))),
                      const SizedBox(height: 2),
                      Text(email, style: const TextStyle(fontSize: 14, color: _cream)),
                    ],
                  ),

                  if (profile?.hasWeightClassInfo == true) ...[
                    const SizedBox(height: 16),
                    _sectionCard(
                      children: [
                        Text('Gewichtsklasse-gegevens', style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.5), fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        Text(
                          'Geslacht: ${profile!.gender == 'M' ? 'Man' : 'Vrouw'}',
                          style: const TextStyle(fontSize: 14, color: _cream),
                        ),
                        const SizedBox(height: 10),
                        if (_isEditingBodyweight)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _bodyweightController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: _cream),
                                  decoration: _fieldDecoration('Lichaamsgewicht (kg)'),
                                ),
                              ),
                              IconButton(
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: _cream),
                                      )
                                    : const Icon(Icons.check, color: _cream),
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
                                  style: const TextStyle(fontSize: 14, color: _cream),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.edit, size: 18, color: _cream.withOpacity(0.7)),
                                onPressed: () => setState(() => _isEditingBodyweight = true),
                              ),
                            ],
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Pas dit aan zodra je gewicht verandert — houdt je gewichtsklasse actueel.',
                          style: TextStyle(fontSize: 11, color: _cream.withOpacity(0.4)),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Statistieken-kaart
                  _sectionCard(
                    children: [
                      Text('Statistieken', style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.5), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Text('Reacties gegeven', style: TextStyle(fontSize: 11, color: _cream.withOpacity(0.5))),
                      const SizedBox(height: 2),
                      FutureBuilder<int>(
                        future: uid != null ? _wallOfFameService.countReactionsGiven(uid) : Future.value(0),
                        builder: (context, countSnapshot) {
                          if (!countSnapshot.hasData) {
                            return const Text('...', style: TextStyle(fontSize: 14, color: _cream));
                          }
                          return Text(
                            '${countSnapshot.data} keer op de Wall of Fame',
                            style: const TextStyle(fontSize: 14, color: _cream),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  OutlinedButton.icon(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Uitloggen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: _red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}