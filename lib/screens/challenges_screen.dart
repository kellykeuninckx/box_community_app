import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/challenge.dart';
import '../models/challenge_result.dart';
import '../models/user_profile.dart';
import '../services/challenge_service.dart';
import '../services/challenge_result_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/logo_pattern_background.dart';

/// Vertaalt een resultaat naar de sectie waaronder het getoond wordt.
/// Null (bij scores van vóór de splitsing) valt in "Onbekend".
String _genderSectionLabel(String? gender) {
  switch (gender) {
    case 'V':
      return 'Vrouwen';
    case 'M':
      return 'Mannen';
    default:
      return 'Onbekend';
  }
}

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

String _formatDutchMonthYear(DateTime date) {
  return '${_months[date.month - 1]} ${date.year}';
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

  // null = "volg de actieve/laatst-afgelopen challenge automatisch";
  // zodra iemand met de pijltjes bladert, onthouden we de gekozen id.
  String? _selectedChallengeId;

  /// Actieve challenge wint; is er geen, dan de meest recente afgelopen
  /// challenge; zijn alle challenges nog toekomstig, dan de eerstvolgende.
  int _defaultIndex(List<Challenge> challenges) {
    final activeIndex = challenges.indexWhere((c) => c.isActiveNow);
    if (activeIndex != -1) return activeIndex;

    final now = DateTime.now();
    for (var i = challenges.length - 1; i >= 0; i--) {
      if (challenges[i].endDate.isBefore(now)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const LogoPatternBackground(),
        StreamBuilder<UserProfile?>(
          stream: UserProfileService().currentUserProfile,
          builder: (context, profileSnapshot) {
            final isAdmin = profileSnapshot.data?.isAdmin ?? false;

            return StreamBuilder<List<Challenge>>(
              stream: _challengeService.allChallenges,
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

                final rawChallenges = challengeSnapshot.data ?? [];
                // Niet-admins zien nog-niet-gestarte challenges niet — die
                // blijven een verrassing tot de startdatum aanbreekt.
                final now = DateTime.now();
                final challenges = isAdmin
                    ? rawChallenges
                    : rawChallenges
                          .where((c) => !c.startDate.isAfter(now))
                          .toList();
                final selectedIndex = challenges.isEmpty
                    ? -1
                    : () {
                        final idx = _selectedChallengeId == null
                            ? -1
                            : challenges.indexWhere(
                                (c) => c.id == _selectedChallengeId,
                              );
                        return idx != -1 ? idx : _defaultIndex(challenges);
                      }();
                final challenge = selectedIndex == -1
                    ? null
                    : challenges[selectedIndex];

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
                            'Nog geen challenges geplaatst.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _cream.withOpacity(0.6)),
                          ),
                        ),
                      )
                    else ...[
                      if (challenges.length > 1)
                        _ChallengeNav(
                          label: _formatDutchMonthYear(challenge.startDate),
                          canGoOlder: selectedIndex > 0,
                          canGoNewer: selectedIndex < challenges.length - 1,
                          onOlder: () => setState(
                            () => _selectedChallengeId =
                                challenges[selectedIndex - 1].id,
                          ),
                          onNewer: () => setState(
                            () => _selectedChallengeId =
                                challenges[selectedIndex + 1].id,
                          ),
                        ),
                      Expanded(
                        child: _ChallengeDetail(
                          challenge: challenge,
                          readOnly: !challenge.isActiveNow,
                          resultService: _resultService,
                        ),
                      ),
                    ],
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

class _ChallengeNav extends StatelessWidget {
  final String label;
  final bool canGoOlder;
  final bool canGoNewer;
  final VoidCallback onOlder;
  final VoidCallback onNewer;

  const _ChallengeNav({
    required this.label,
    required this.canGoOlder,
    required this.canGoNewer,
    required this.onOlder,
    required this.onNewer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: canGoOlder ? onOlder : null,
            icon: Icon(
              Icons.chevron_left,
              color: canGoOlder ? _cream : _cream.withOpacity(0.2),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _cream,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: canGoNewer ? onNewer : null,
            icon: Icon(
              Icons.chevron_right,
              color: canGoNewer ? _cream : _cream.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeDetail extends StatelessWidget {
  final Challenge challenge;
  final bool readOnly;
  final ChallengeResultService resultService;

  const _ChallengeDetail({
    required this.challenge,
    required this.readOnly,
    required this.resultService,
  });

  String get _statusLabel {
    if (!readOnly) return 'Tot en met ${_formatDutchDate(challenge.endDate)}';
    if (DateTime.now().isBefore(challenge.startDate)) {
      return 'Start op ${_formatDutchDate(challenge.startDate)}';
    }
    return 'Afgelopen op ${_formatDutchDate(challenge.endDate)}';
  }

  String _formatValue(ChallengeResult result) {
    if (challenge.scoreType != ChallengeScoreType.reps)
      return result.formattedValue;
    return '${result.rawValue.round()} ${challenge.unit}';
  }

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
                          challenge.scoreType == ChallengeScoreType.reps
                              ? '${challenge.unit[0].toUpperCase()}${challenge.unit.substring(1)}'
                              : challenge.scoreType.label,
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
                    _statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: readOnly ? FontWeight.w600 : null,
                      color: readOnly
                          ? _cream.withOpacity(0.4)
                          : _cream.withOpacity(0.5),
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
              // Splitsen per geslacht gebeurt na de dedup, met behoud van
              // volgorde (een oplopend gesorteerde lijst blijft oplopend
              // gesorteerd na filteren).
              final seenUids = <String>{};
              final women = <ChallengeResult>[];
              final men = <ChallengeResult>[];
              final unknown = <ChallengeResult>[];
              for (final result in allResults) {
                if (!seenUids.add(result.uid)) continue;
                switch (result.gender) {
                  case 'V':
                    women.add(result);
                    break;
                  case 'M':
                    men.add(result);
                    break;
                  default:
                    unknown.add(result);
                }
              }

              if (women.isEmpty && men.isEmpty && unknown.isEmpty) {
                return Center(
                  child: Text(
                    'Nog niemand heeft een score ingevuld.\nWees de eerste!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _cream.withOpacity(0.6)),
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                children: [
                  if (women.isNotEmpty) ..._genderSection(context, women),
                  if (men.isNotEmpty) ..._genderSection(context, men),
                  if (unknown.isNotEmpty) ..._genderSection(context, unknown),
                ],
              );
            },
          ),
        ),
        if (!readOnly)
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

  List<Widget> _genderSection(
    BuildContext context,
    List<ChallengeResult> results,
  ) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          _genderSectionLabel(results.first.gender),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _cream,
          ),
        ),
      ),
      ...results.asMap().entries.map((entry) {
        final index = entry.key;
        final result = entry.value;
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
                  _formatValue(result),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _cream,
                  ),
                ),
                if (isMine && !readOnly)
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
    ];
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
          'Dit verwijdert jouw score van ${_formatValue(result)}. Dit kan niet ongedaan gemaakt worden.',
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
  final _profileService = UserProfileService();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _repsController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingProfile = true;
  bool _needsGender = false;
  String _gender = 'M';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
    _repsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    double rawValue;
    if (widget.challenge.scoreType != ChallengeScoreType.reps) {
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

    if (_needsGender) {
      await _profileService.setGender(_gender);
    }

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
          Text(
            'Score invullen: ${widget.challenge.title}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _cream,
            ),
          ),
          const SizedBox(height: 16),

          if (widget.challenge.scoreType != ChallengeScoreType.reps)
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
                labelText: 'Aantal ${widget.challenge.unit}',
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
                    showCheckmark: false,
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
                    showCheckmark: false,
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

class _NewChallengeSheet extends StatefulWidget {
  final ChallengeService service;

  const _NewChallengeSheet({required this.service});

  @override
  State<_NewChallengeSheet> createState() => _NewChallengeSheetState();
}

class _NewChallengeSheetState extends State<_NewChallengeSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitLabelController = TextEditingController();
  ChallengeScoreType _scoreType = ChallengeScoreType.time;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _unitLabelController.dispose();
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
      unitLabel: _scoreType == ChallengeScoreType.reps
          ? _unitLabelController.text
          : null,
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
                showCheckmark: false,
                selectedColor: _red,
                backgroundColor: _chipBg,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : _cream,
                ),
                onSelected: (_) => setState(() => _scoreType = type),
              );
            }).toList(),
          ),

          if (_scoreType == ChallengeScoreType.reps) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _unitLabelController,
              style: const TextStyle(color: _cream),
              decoration: InputDecoration(
                labelText: 'Eenheid (optioneel)',
                hintText: 'Leeg = reps',
                helperText: 'Bijvoorbeeld: burpees, calorieën, meters',
                helperMaxLines: 2,
                labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
                hintStyle: TextStyle(color: _cream.withOpacity(0.3)),
                helperStyle: TextStyle(color: _cream.withOpacity(0.4)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
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
