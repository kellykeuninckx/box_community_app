import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge.dart';
import '../models/challenge_result.dart';
import '../models/user_profile.dart';
import '../services/challenge_service.dart';
import '../services/challenge_result_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/logo_pattern_background.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _cardColor = Color(0xFF1B2E5C);
const _chipBg = Color(0x14F0EDC8); // cream @ ~8% opacity

const _weekdays = [
  'maandag',
  'dinsdag',
  'woensdag',
  'donderdag',
  'vrijdag',
  'zaterdag',
  'zondag',
];
const _months = [
  'januari',
  'februari',
  'maart',
  'april',
  'mei',
  'juni',
  'juli',
  'augustus',
  'september',
  'oktober',
  'november',
  'december',
];

String _formatDutchDate(DateTime date) {
  final weekday = _weekdays[date.weekday - 1];
  final month = _months[date.month - 1];
  return '$weekday ${date.day} $month ${date.year}';
}

/// Losgetrokken van een eigen Scaffold zodat dit ingebed kan worden als tab
/// binnen de Leaderboards-tegel (zie leaderboards_screen.dart).
class ChallengesBody extends StatefulWidget {
  const ChallengesBody({super.key});

  @override
  State<ChallengesBody> createState() => _ChallengesBodyState();
}

class _ChallengesBodyState extends State<ChallengesBody> {
  final _challengeService = ChallengeService();
  final _resultService = ChallengeResultService();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const LogoPatternBackground(),
        StreamBuilder<UserProfile?>(
          stream: UserProfileService().currentUserProfile,
          builder: (context, profileSnapshot) {
            final isAdmin = profileSnapshot.data?.isAdmin ?? false;

            return StreamBuilder<Challenge?>(
              stream: _challengeService.activeChallenge,
              builder: (context, challengeSnapshot) {
                if (challengeSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (challengeSnapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Fout bij laden: ${challengeSnapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }

                final challenge = challengeSnapshot.data;

                return Column(
                  children: [
                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: OutlinedButton.icon(
                          onPressed: () => _showNewChallengeSheet(context),
                          icon: const Icon(Icons.add, size: 18, color: _cream),
                          label: const Text(
                            'Nieuwe challenge',
                            style: TextStyle(color: _cream),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _cream.withOpacity(0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size.fromHeight(40),
                          ),
                        ),
                      ),
                    if (challenge == null)
                      Expanded(
                        child: Center(
                          child: Text(
                            'Geen actieve challenge op dit moment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _cream.withOpacity(0.6)),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: _ActiveChallenge(
                          challenge: challenge,
                          resultService: _resultService,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showNewChallengeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      builder: (_) => _NewChallengeSheet(service: _challengeService),
    );
  }
}

class _ActiveChallenge extends StatelessWidget {
  final Challenge challenge;
  final ChallengeResultService resultService;

  const _ActiveChallenge({
    required this.challenge,
    required this.resultService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          challenge.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _cream,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          challenge.scoreType.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (challenge.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      challenge.description,
                      style: const TextStyle(fontSize: 13, color: _cream),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Tot en met ${_formatDutchDate(challenge.endDate)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: _cream.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ChallengeResult>>(
            stream: resultService.resultsFor(challenge.id),
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

              final allResults = snapshot.data ?? [];

              // De query staat al oplopend op normalizedScore, dus de eerste
              // keer dat iemands uid voorbij komt is meteen zijn beste poging.
              // Latere (mindere) pogingen van diezelfde persoon slaan we hier
              // over — ze blijven gewoon bewaard, alleen niet los getoond.
              final seenUids = <String>{};
              final results = <ChallengeResult>[
                for (final result in allResults)
                  if (seenUids.add(result.uid)) result,
              ];

              if (results.isEmpty) {
                return Center(
                  child: Text(
                    'Nog niemand heeft een score ingevuld.\nWees de eerste!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _cream.withOpacity(0.6)),
                  ),
                );
              }

              final currentUid = FirebaseAuth.instance.currentUser?.uid;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  final isMine = currentUid != null && currentUid == result.uid;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: _chipBg,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _cream,
                          ),
                        ),
                      ),
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
                            result.formattedValue,
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
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed: () => _showSubmitSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Score invullen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              minimumSize: const Size.fromHeight(44),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, ChallengeResult result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text(
          'Score verwijderen?',
          style: TextStyle(color: _cream),
        ),
        content: Text(
          'Dit verwijdert jouw score van ${result.formattedValue}. Dit kan niet ongedaan gemaakt worden.',
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
              resultService.deleteResult(result.id);
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
      backgroundColor: _cardColor,
      builder: (_) =>
          _SubmitResultSheet(service: resultService, challenge: challenge),
    );
  }
}

class _SubmitResultSheet extends StatefulWidget {
  final ChallengeResultService service;
  final Challenge challenge;

  const _SubmitResultSheet({required this.service, required this.challenge});

  @override
  State<_SubmitResultSheet> createState() => _SubmitResultSheetState();
}

class _SubmitResultSheetState extends State<_SubmitResultSheet> {
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _repsController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _repsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    double rawValue;
    if (widget.challenge.scoreType == ChallengeScoreType.time) {
      final minutes = int.tryParse(_minutesController.text) ?? 0;
      final seconds = int.tryParse(_secondsController.text) ?? 0;
      if (seconds < 0 || seconds > 59) {
        setState(() => _errorMessage = 'Seconden moet tussen 0 en 59 liggen.');
        return;
      }
      rawValue = (minutes * 60 + seconds).toDouble();
    } else {
      rawValue = double.tryParse(_repsController.text) ?? 0;
    }

    if (rawValue <= 0) {
      setState(() => _errorMessage = 'Vul een geldige score in.');
      return;
    }

    setState(() => _isSubmitting = true);

    final note = _noteController.text.trim();
    await widget.service.submitResult(
      challengeId: widget.challenge.id,
      scoreType: widget.challenge.scoreType,
      rawValue: rawValue,
      note: note.isEmpty ? null : note,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Score invullen: ${widget.challenge.title}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _cream,
            ),
          ),
          const SizedBox(height: 16),

          if (widget.challenge.scoreType == ChallengeScoreType.time)
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
            )
          else
            TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: _cream),
              decoration: InputDecoration(
                labelText: 'Aantal reps',
                labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          const SizedBox(height: 16),

          TextField(
            controller: _noteController,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(
              labelText: 'Opmerking (optioneel)',
              hintText: 'Bijvoorbeeld: gescaled',
              labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
              hintStyle: TextStyle(color: _cream.withOpacity(0.3)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

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

class _NewChallengeSheet extends StatefulWidget {
  final ChallengeService service;

  const _NewChallengeSheet({required this.service});

  @override
  State<_NewChallengeSheet> createState() => _NewChallengeSheetState();
}

class _NewChallengeSheetState extends State<_NewChallengeSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  ChallengeScoreType _scoreType = ChallengeScoreType.time;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vul een titel in.');
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      setState(
        () => _errorMessage = 'Einddatum kan niet vóór de startdatum liggen.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await widget.service.addChallenge(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      scoreType: _scoreType,
      startDate: _startDate,
      endDate: _endDate,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
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
            'Nieuwe challenge',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _cream,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _titleController,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(
              labelText: 'Titel',
              hintText: 'Bijvoorbeeld: 1km row for time',
              labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
              hintStyle: TextStyle(color: _cream.withOpacity(0.3)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descriptionController,
            maxLines: 3,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(
              labelText: 'Omschrijving (optioneel)',
              labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            children: ChallengeScoreType.values.map((type) {
              final isSelected = type == _scoreType;
              return ChoiceChip(
                label: Text(type.label),
                selected: isSelected,
                selectedColor: _red,
                backgroundColor: _chipBg,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : _cream,
                ),
                onSelected: (_) => setState(() => _scoreType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: _cream,
                  ),
                  label: Text(
                    _formatDutchDate(_startDate),
                    style: const TextStyle(color: _cream, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _cream.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEndDate,
                  icon: const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: _cream,
                  ),
                  label: Text(
                    _formatDutchDate(_endDate),
                    style: const TextStyle(color: _cream, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _cream.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

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
                : const Text('Plaatsen'),
          ),
        ],
      ),
    );
  }
}
