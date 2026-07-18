import 'package:flutter/material.dart';
import '../models/lift_pr.dart';
import '../models/weight_class.dart';
import '../services/lift_pr_service.dart';
import '../services/user_profile_service.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _navy = Color(0xFF0F1C3F);
const _chipBg = Color(0x14F0EDC8); // cream @ ~8% opacity

class LiftLeaderboardScreen extends StatefulWidget {
  const LiftLeaderboardScreen({super.key});

  @override
  State<LiftLeaderboardScreen> createState() => _LiftLeaderboardScreenState();
}

class _LiftLeaderboardScreenState extends State<LiftLeaderboardScreen> {
  LiftType _selectedLift = LiftType.deadlift;
  final _service = LiftPrService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lift leaderboard'),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: LiftType.values.map((lift) {
                final isSelected = lift == _selectedLift;
                return ChoiceChip(
                  label: Text(lift.label),
                  selected: isSelected,
                  selectedColor: _red,
                  backgroundColor: _chipBg,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : _cream),
                  onSelected: (_) => setState(() => _selectedLift = lift),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<LiftPr>>(
              stream: _service.prsFor(_selectedLift.name),
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
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  );
                }

                final prs = snapshot.data ?? [];

                if (prs.isEmpty) {
                  return Center(
                    child: Text(
                      'Nog geen PR\'s ingevuld.\nWees de eerste!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _cream.withOpacity(0.6)),
                    ),
                  );
                }

                final women = prs.where((p) => p.gender == 'V').toList();
                final men = prs.where((p) => p.gender == 'M').toList();

                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  children: [
                    if (women.isNotEmpty) ..._genderSection('Vrouwen', women),
                    if (men.isNotEmpty) ..._genderSection('Mannen', men),
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
              label: const Text('PR invullen'),
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
    );
  }

  List<Widget> _genderSection(String title, List<LiftPr> prs) {
    final grouped = <String, List<LiftPr>>{};
    for (final pr in prs) {
      final weightClass = WeightClass.forWeight(pr.gender, pr.bodyweightKg);
      grouped.putIfAbsent(weightClass, () => []).add(pr);
    }

    final widgets = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _cream),
        ),
      ),
    ];

    for (final entry in grouped.entries) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            entry.key,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _red),
          ),
        ),
      );

      final sorted = List<LiftPr>.from(entry.value)
        ..sort((a, b) => b.weightKg.compareTo(a.weightKg));

      widgets.addAll(sorted.map((pr) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              dense: true,
              title: Text(pr.nickname, style: const TextStyle(color: _cream)),
              trailing: Text(
                '${pr.weightKg.toStringAsFixed(1)} kg',
                style: const TextStyle(fontWeight: FontWeight.w600, color: _cream),
              ),
            ),
          )));
    }

    return widgets;
  }

  void _showSubmitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16264B),
      builder: (_) => _SubmitPrSheet(service: _service, initialLift: _selectedLift),
    );
  }
}

class _SubmitPrSheet extends StatefulWidget {
  final LiftPrService service;
  final LiftType initialLift;

  const _SubmitPrSheet({required this.service, required this.initialLift});

  @override
  State<_SubmitPrSheet> createState() => _SubmitPrSheetState();
}

class _SubmitPrSheetState extends State<_SubmitPrSheet> {
  final _profileService = UserProfileService();
  final _weightController = TextEditingController();
  final _bodyweightController = TextEditingController();

  late LiftType _selectedLift;
  String _gender = 'M';
  bool _isSubmitting = false;
  bool _isLoadingProfile = true;
  bool _needsWeightClassInfo = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedLift = widget.initialLift;
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileService.currentUserProfile.first;
    if (!mounted) return;

    setState(() {
      _needsWeightClassInfo = profile == null || !profile.hasWeightClassInfo;
      _isLoadingProfile = false;
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _bodyweightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (weight == null || weight <= 0) {
      setState(() => _errorMessage = 'Vul een geldig gewicht in voor je lift.');
      return;
    }

    if (_needsWeightClassInfo) {
      final bodyweight = double.tryParse(_bodyweightController.text.replaceAll(',', '.'));
      if (bodyweight == null || bodyweight <= 0) {
        setState(() => _errorMessage = 'Vul je lichaamsgewicht in.');
        return;
      }

      setState(() => _isSubmitting = true);
      await _profileService.setWeightClassInfo(gender: _gender, bodyweightKg: bodyweight);
    } else {
      setState(() => _isSubmitting = true);
    }

    await widget.service.submitPr(lift: _selectedLift.name, weightKg: weight);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
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
          const Text('Nieuwe PR invullen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _cream)),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            children: LiftType.values.map((lift) {
              final isSelected = lift == _selectedLift;
              return ChoiceChip(
                label: Text(lift.label),
                selected: isSelected,
                selectedColor: _red,
                backgroundColor: _chipBg,
                labelStyle: TextStyle(color: isSelected ? Colors.white : _cream),
                onSelected: (_) => setState(() => _selectedLift = lift),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(
              labelText: 'Gewicht (kg)',
              labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          if (_needsWeightClassInfo) ...[
            const SizedBox(height: 16),
            Text(
              'Voor de gewichtsklasse-indeling hebben we dit eenmalig nodig:',
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
                    labelStyle: TextStyle(color: _gender == 'M' ? Colors.white : _cream),
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
                    labelStyle: TextStyle(color: _gender == 'V' ? Colors.white : _cream),
                    onSelected: (_) => setState(() => _gender = 'V'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyweightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: _cream),
              decoration: InputDecoration(
                labelText: 'Lichaamsgewicht (kg)',
                labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Opslaan'),
          ),
        ],
      ),
    );
  }
}