enum WodScoreType { time, reps }

class Wod {
  final String name;
  final String category;
  final WodScoreType scoreType;
  final List<String> lines;

  const Wod({
    required this.name,
    required this.category,
    required this.scoreType,
    required this.lines,
  });
}

/// Curated lijst van de bekendste benchmark-WOD's, in het Engels — makkelijk
/// uit te breiden door hier gewoon een regel aan toe te voegen.
const List<Wod> benchmarkWods = [
  // Girls
  Wod(name: 'Fran', category: 'Girls', scoreType: WodScoreType.time, lines: ['21-15-9 reps for time:', 'Thrusters (43/30 kg)', 'Pull-ups']),
  Wod(name: 'Grace', category: 'Girls', scoreType: WodScoreType.time, lines: ['30 reps for time:', 'Clean and jerk (61/43 kg)']),
  Wod(name: 'Helen', category: 'Girls', scoreType: WodScoreType.time, lines: ['3 rounds for time:', '400m run', '21 kettlebell swings (24/16 kg)', '12 pull-ups']),
  Wod(name: 'Diane', category: 'Girls', scoreType: WodScoreType.time, lines: ['21-15-9 reps for time:', 'Deadlifts (102/70 kg)', 'Handstand push-ups']),
  Wod(name: 'Annie', category: 'Girls', scoreType: WodScoreType.time, lines: ['50-40-30-20-10 reps for time:', 'Double-unders', 'Sit-ups']),
  Wod(name: 'Karen', category: 'Girls', scoreType: WodScoreType.time, lines: ['150 wall-ball shots for time (9/6 kg)']),
  Wod(name: 'Isabel', category: 'Girls', scoreType: WodScoreType.time, lines: ['30 snatches for time (61/43 kg)']),
  Wod(name: 'Nancy', category: 'Girls', scoreType: WodScoreType.time, lines: ['5 rounds for time:', '400m run', '15 overhead squats (43/30 kg)']),
  Wod(name: 'Jackie', category: 'Girls', scoreType: WodScoreType.time, lines: ['For time:', '1000m row', '50 thrusters (20/15 kg)', '30 pull-ups']),
  Wod(name: 'Cindy', category: 'Girls', scoreType: WodScoreType.reps, lines: ['20-minute AMRAP:', '5 pull-ups', '10 push-ups', '15 air squats']),
  Wod(name: 'Angie', category: 'Girls', scoreType: WodScoreType.time, lines: ['For time:', '100 pull-ups', '100 push-ups', '100 sit-ups', '100 air squats']),
  Wod(name: 'Elizabeth', category: 'Girls', scoreType: WodScoreType.time, lines: ['21-15-9 reps for time:', 'Clean (61/43 kg)', 'Ring dips']),

  // Hero WODs
  Wod(name: 'Murph', category: 'Hero WODs', scoreType: WodScoreType.time, lines: ['For time:', '1 mile run', '100 pull-ups', '200 push-ups', '300 squats', '1 mile run', '(wear a 9/6 kg vest if you have one)']),
  Wod(name: 'DT', category: 'Hero WODs', scoreType: WodScoreType.time, lines: ['5 rounds for time:', '12 deadlifts (70/47 kg)', '9 hang power cleans', '6 push jerks']),
  Wod(name: 'JT', category: 'Hero WODs', scoreType: WodScoreType.time, lines: ['21-15-9 reps for time:', 'Handstand push-ups', 'Ring dips', 'Push-ups']),
  Wod(name: 'Chad', category: 'Hero WODs', scoreType: WodScoreType.time, lines: ['For time:', '1000 step-ups holding a 20 kg plate']),
  Wod(name: 'Randy', category: 'Hero WODs', scoreType: WodScoreType.time, lines: ['75 power snatches for time (34/24 kg)']),
  Wod(name: 'Michael', category: 'Hero WODs', scoreType: WodScoreType.time, lines: ['3 rounds for time:', '800m run', '50 back extensions', '50 sit-ups']),
  Wod(name: 'Josh', category: 'Hero WODs', scoreType: WodScoreType.time, lines: ['21-15-9-15-21 reps for time:', 'Overhead squats (43/30 kg)', 'Pull-ups']),
  Wod(name: 'Kalsu', category: 'Hero WODs', scoreType: WodScoreType.time, lines: ['100 thrusters for time (61/43 kg)', 'Every minute on the minute: 5 burpees']),
];