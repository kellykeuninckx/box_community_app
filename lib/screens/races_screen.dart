import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/race_result.dart';
import '../services/race_result_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/logo_pattern_background.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _chipBg = Color(0x14F0EDC8); // cream @ ~8% opacity

/// Losgetrokken van een eigen Scaffold zodat dit ingebed kan worden als tab
/// binnen de Leaderboards-tegel (zie leaderboards_screen.dart).
class RacesBody extends StatefulWidget {
  const RacesBody({super.key});

  @override
  State<RacesBody> createState() => _RacesBodyState();
}

class _RacesBodyState extends State<RacesBody> {
  RaceType _selectedType = RaceType.hyrox;
  final _service = RaceResultService();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const LogoPatternBackground(),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                children: RaceType.values.map((type) {
                  final isSelected = type == _selectedType;
                  return ChoiceChip(
                    label: Text(type.label),
                    selected: isSelected,
                    selectedColor: _red,
                    backgroundColor: _chipBg,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : _cream,
                    ),
                    onSelected: (_) => setState(() => _selectedType = type),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<RaceResult>>(
                stream: _service.resultsFor(_selectedType),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Fout bij laden: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }

                  final results = snapshot.data ?? [];

                  if (results.isEmpty) {
                    return Center(
                      child: Text(
                        'Nog geen tijden ingevuld.\nWees de eerste!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _cream.withOpacity(0.6)),
                      ),
                    );
                  }

                  final women = results.where((r) => r.gender == 'V').toList();
                  final men = results.where((r) => r.gender == 'M').toList();

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    children: [
                      if (women.isNotEmpty)
                        ..._genderSection(context, 'Vrouwen', women),
                      if (men.isNotEmpty)
                        ..._genderSection(context, 'Mannen', men),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton.icon(
                onPressed: () => _showSubmitSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('Tijd invullen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Solo en doubles worden apart gehouden — een duo-tijd is niet eerlijk te
  /// vergelijken met een solo-tijd.
  List<Widget> _genderSection(
    BuildContext context,
    String title,
    List<RaceResult> results,
  ) {
    final grouped = <RaceMode, List<RaceResult>>{};
    for (final result in results) {
      grouped.putIfAbsent(result.mode, () => []).add(result);
    }

    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _cream,
          ),
        ),
      ),
    ];

    for (final mode in RaceMode.values) {
      final modeResults = grouped[mode];
      if (modeResults == null || modeResults.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            mode.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _red,
            ),
          ),
        ),
      );

      final sorted = List<RaceResult>.from(modeResults)
        ..sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));

      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      widgets.addAll(
        sorted.map((result) {
          final isMine = currentUid != null && currentUid == result.uid;

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              title: Text(
                result.nickname,
                style: const TextStyle(color: _cream),
              ),
              subtitle: result.note != null && result.note!.isNotEmpty
                  ? Text(
                      result.note!,
                      style: TextStyle(
                        color: _cream.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    result.formattedTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _cream,
                    ),
                  ),
                  if (isMine)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: _cream.withOpacity(0.5),
                      ),
                      onPressed: () => _confirmDelete(context, result),
                    ),
                ],
              ),
            ),
          );
        }),
      );
    }

    return widgets;
  }

  void _confirmDelete(BuildContext context, RaceResult result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B2E5C),
        title: const Text('Tijd verwijderen?', style: TextStyle(color: _cream)),
        content: Text(
          'Dit verwijdert jouw ${result.raceType.label}-tijd van ${result.formattedTime}. Dit kan niet ongedaan gemaakt worden.',
          style: TextStyle(color: _cream.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuleer',
              style: TextStyle(color: _cream.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              _service.deleteResult(result.id);
              Navigator.of(context).pop();
            },
            child: const Text('Verwijder', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
  }

  void _showSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16264B),
      builder: (_) =>
          _SubmitRaceSheet(service: _service, initialType: _selectedType),
    );
  }
}

class _SubmitRaceSheet extends StatefulWidget {
  final RaceResultService service;
  final RaceType initialType;

  const _SubmitRaceSheet({required this.service, required this.initialType});

  @override
  State<_SubmitRaceSheet> createState() => _SubmitRaceSheetState();
}

class _SubmitRaceSheetState extends State<_SubmitRaceSheet> {
  final _profileService = UserProfileService();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _noteController = TextEditingController();

  late RaceType _selectedType;
  RaceMode _selectedMode = RaceMode.solo;
  String _gender = 'M';
  bool _isSubmitting = false;
  bool _isLoadingProfile = true;
  bool _needsGender = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.currentUserProfile.first;
    if (!mounted) return;

    setState(() {
      _needsGender = profile == null || profile.gender == null;
      _isLoadingProfile = false;
    });
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;

    if (seconds < 0 || seconds > 59) {
      setState(() => _errorMessage = 'Seconden moet tussen 0 en 59 liggen.');
      return;
    }

    final totalSeconds = minutes * 60 + seconds;
    if (totalSeconds <= 0) {
      setState(() => _errorMessage = 'Vul een geldige tijd in.');
      return;
    }

    final note = _noteController.text.trim();
    if (_selectedMode == RaceMode.doubles && note.isEmpty) {
      setState(
        () => _errorMessage = 'Vul bij Doubles in met wie je het gedaan hebt.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    if (_needsGender) {
      await _profileService.setGender(_gender);
    }

    await widget.service.submitResult(
      raceType: _selectedType,
      mode: _selectedMode,
      timeSeconds: totalSeconds,
      note: note.isEmpty ? null : note,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Nieuwe tijd invullen',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _cream,
            ),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            children: RaceType.values.map((type) {
              final isSelected = type == _selectedType;
              return ChoiceChip(
                label: Text(type.label),
                selected: isSelected,
                selectedColor: _red,
                backgroundColor: _chipBg,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : _cream,
                ),
                onSelected: (_) => setState(() => _selectedType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            children: RaceMode.values.map((mode) {
              final isSelected = mode == _selectedMode;
              return ChoiceChip(
                label: Text(mode.label),
                selected: isSelected,
                selectedColor: _red,
                backgroundColor: _chipBg,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : _cream,
                ),
                onSelected: (_) => setState(() => _selectedMode = mode),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: _cream),
                  decoration: InputDecoration(
                    labelText: 'Minuten',
                    labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _secondsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: _cream),
                  decoration: InputDecoration(
                    labelText: 'Seconden',
                    labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _noteController,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(
              labelText: _selectedMode == RaceMode.doubles
                  ? 'Met wie (verplicht)'
                  : 'Opmerking (optioneel)',
              hintText: _selectedMode == RaceMode.doubles
                  ? 'Bijvoorbeeld: met Jan'
                  : 'Bijvoorbeeld: Hyrox Utrecht',
              labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
              hintStyle: TextStyle(color: _cream.withOpacity(0.3)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          if (_needsGender) ...[
            const SizedBox(height: 16),
            Text(
              'Voor de man/vrouw-indeling hebben we dit eenmalig nodig:',
              style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.6)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Man'),
                    selected: _gender == 'M',
                    selectedColor: _red,
                    backgroundColor: _chipBg,
                    labelStyle: TextStyle(
                      color: _gender == 'M' ? Colors.white : _cream,
                    ),
                    onSelected: (_) => setState(() => _gender = 'M'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Vrouw'),
                    selected: _gender == 'V',
                    selectedColor: _red,
                    backgroundColor: _chipBg,
                    labelStyle: TextStyle(
                      color: _gender == 'V' ? Colors.white : _cream,
                    ),
                    onSelected: (_) => setState(() => _gender = 'V'),
                  ),
                ),
              ],
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Opslaan'),
          ),
        ],
      ),
    );
  }
}
