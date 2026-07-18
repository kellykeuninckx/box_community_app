import 'package:flutter/material.dart';
import '../models/wod.dart';
import '../models/wod_score.dart';
import '../services/wod_service.dart';

class WodDetailScreen extends StatelessWidget {
  final Wod wod;

  const WodDetailScreen({super.key, required this.wod});

  @override
  Widget build(BuildContext context) {
    final service = WodService();

    return Scaffold(
      appBar: AppBar(
        title: Text(wod.name),
        backgroundColor: const Color(0xFF0F1C3F),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF8B1E2B).withOpacity(0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wod.description, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  wod.scoreType == WodScoreType.time
                      ? 'Score: tijd'
                      : 'Score: rondes + reps (AMRAP)',
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<WodScore>>(
              stream: service.scoresFor(wod.name),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final scores = snapshot.data ?? [];

                if (scores.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nog geen scores ingevuld.\nWees de eerste!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: scores.length,
                  itemBuilder: (context, index) {
                    final score = scores[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(score.nickname),
                        trailing: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              score.formattedScore,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (score.isScaled)
                              const Text(
                                'Scaled',
                                style: TextStyle(fontSize: 10, color: Colors.black45),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B1E2B),
        onPressed: () => _showScoreSheet(context, service),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showScoreSheet(BuildContext context, WodService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ScoreSheet(wod: wod, service: service),
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

  bool _isScaled = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _roundsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

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
      );
    }

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
            'Score invullen — ${widget.wod.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          if (widget.wod.scoreType == WodScoreType.time)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Minuten',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _secondsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Seconden',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
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
                    decoration: InputDecoration(
                      labelText: 'Rondes',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Extra reps',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 8),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Scaled'),
            subtitle: const Text('Aangepaste gewichten/bewegingen'),
            value: _isScaled,
            activeColor: const Color(0xFF8B1E2B),
            onChanged: (value) => setState(() => _isScaled = value),
          ),

          if (_errorMessage != null) ...[
            Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 8),
          ],

          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E2B),
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