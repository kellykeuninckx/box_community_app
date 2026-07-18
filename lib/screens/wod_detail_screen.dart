import 'package:flutter/material.dart';
import '../models/wod.dart';
import '../models/wod_score.dart';
import '../services/wod_service.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _navy = Color(0xFF0F1C3F);
const _cardColor = Color(0xFF1B2E5C);

class WodDetailScreen extends StatelessWidget {
  final Wod wod;

  const WodDetailScreen({super.key, required this.wod});

  @override
  Widget build(BuildContext context) {
    final service = WodService();

    return Scaffold(
      appBar: AppBar(
        title: Text(wod.name),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      body: StreamBuilder<List<WodScore>>(
        stream: service.scoresFor(wod.name),
        builder: (context, snapshot) {
          Widget resultsSection;

          if (snapshot.connectionState == ConnectionState.waiting) {
            resultsSection = const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            resultsSection = Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Fout bij laden: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            );
          } else {
            final scores = snapshot.data ?? [];

            if (scores.isEmpty) {
              resultsSection = Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Nog geen scores ingevuld.\nWees de eerste!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _cream.withOpacity(0.6)),
                  ),
                ),
              );
            } else {
              resultsSection = Card(
                color: _cardColor,
                child: Column(
                  children: [
                    for (int i = 0; i < scores.length; i++) ...[
                      _ScoreRow(score: scores[i]),
                      if (i < scores.length - 1)
                        Divider(height: 1, color: _cream.withOpacity(0.1)),
                    ],
                  ],
                ),
              );
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: _cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wod.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _cream),
                      ),
                      const SizedBox(height: 8),
                      for (final line in wod.lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            line,
                            style: TextStyle(fontSize: 13, color: _cream.withOpacity(0.85)),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        wod.scoreType == WodScoreType.time ? 'Score: time' : 'Score: rounds + reps (AMRAP)',
                        style: TextStyle(fontSize: 11, color: _cream.withOpacity(0.5), fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              resultsSection,
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _red,
        onPressed: () => _showScoreSheet(context, service),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showScoreSheet(BuildContext context, WodService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      builder: (_) => _ScoreSheet(wod: wod, service: service),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final WodScore score;

  const _ScoreRow({required this.score});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(score.nickname, style: const TextStyle(color: _cream)),
      subtitle: score.note != null && score.note!.isNotEmpty
          ? Text(score.note!, style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.5)))
          : null,
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            score.formattedScore,
            style: const TextStyle(fontWeight: FontWeight.w600, color: _cream),
          ),
          if (score.isScaled)
            Text('Scaled', style: TextStyle(fontSize: 10, color: _cream.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _ScoreSheet extends StatefulWidget {
  final Wod wod;
  final WodService service;

  const _ScoreSheet({required this.wod, required this.service});

  @override
  State<_ScoreSheet> createState() => _ScoreSheetState();
}

class _ScoreSheetState extends State<_ScoreSheet> {
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _roundsController = TextEditingController();
  final _repsController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isScaled = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _roundsController.dispose();
    _repsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    final note = _isScaled && _noteController.text.trim().isNotEmpty
        ? _noteController.text.trim()
        : null;

    if (widget.wod.scoreType == WodScoreType.time) {
      final minutes = int.tryParse(_minutesController.text) ?? 0;
      final seconds = int.tryParse(_secondsController.text) ?? 0;

      if (minutes == 0 && seconds == 0) {
        setState(() => _errorMessage = 'Vul een tijd in.');
        return;
      }

      setState(() => _isSubmitting = true);

      await widget.service.submitTimeScore(
        wodName: widget.wod.name,
        timeInSeconds: minutes * 60 + seconds,
        isScaled: _isScaled,
        note: note,
      );
    } else {
      final rounds = int.tryParse(_roundsController.text) ?? 0;
      final reps = int.tryParse(_repsController.text) ?? 0;

      if (rounds == 0 && reps == 0) {
        setState(() => _errorMessage = 'Vul rondes en/of reps in.');
        return;
      }

      setState(() => _isSubmitting = true);

      await widget.service.submitRepsScore(
        wodName: widget.wod.name,
        rounds: rounds,
        extraReps: reps,
        isScaled: _isScaled,
        note: note,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
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
            'Score invullen — ${widget.wod.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _cream),
          ),
          const SizedBox(height: 16),

          if (widget.wod.scoreType == WodScoreType.time)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: _cream),
                    decoration: _decoration('Minuten'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _secondsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: _cream),
                    decoration: _decoration('Seconden'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _roundsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: _cream),
                    decoration: _decoration('Rondes'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: _cream),
                    decoration: _decoration('Extra reps'),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Scaled', style: TextStyle(color: _cream)),
            subtitle: Text('Aangepaste gewichten/bewegingen', style: TextStyle(color: _cream.withOpacity(0.5))),
            value: _isScaled,
            activeColor: _red,
            onChanged: (value) => setState(() => _isScaled = value),
          ),

          if (_isScaled) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: const TextStyle(color: _cream),
              decoration: _decoration('Wat heb je aangepast? (optioneel)')
                  .copyWith(hintText: 'Bijv. gewicht 30 kg i.p.v. 43 kg'),
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