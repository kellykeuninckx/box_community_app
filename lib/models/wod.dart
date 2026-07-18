enum WodScoreType { time, reps }

class Wod {
  final String name;
  final String category;
  final WodScoreType scoreType;
  final String description;

  const Wod({
    required this.name,
    required this.category,
    required this.scoreType,
    required this.description,
  });
}

/// Curated lijst van de bekendste benchmark-WOD's — makkelijk uit te breiden
/// door hier gewoon een regel aan toe te voegen.
const List<Wod> benchmarkWods = [
  // Girls
  Wod(name: 'Fran', category: 'Girls', scoreType: WodScoreType.time, description: '21-15-9 thrusters en pull-ups, voor tijd.'),
  Wod(name: 'Grace', category: 'Girls', scoreType: WodScoreType.time, description: '30 clean & jerks, voor tijd.'),
  Wod(name: 'Helen', category: 'Girls', scoreType: WodScoreType.time, description: '3 ronden: 400m hardlopen, 21 kettlebell swings, 12 pull-ups.'),
  Wod(name: 'Diane', category: 'Girls', scoreType: WodScoreType.time, description: '21-15-9 deadlifts en handstand push-ups.'),
  Wod(name: 'Annie', category: 'Girls', scoreType: WodScoreType.time, description: '50-40-30-20-10 double-unders en sit-ups.'),
  Wod(name: 'Karen', category: 'Girls', scoreType: WodScoreType.time, description: '150 wall balls, voor tijd.'),
  Wod(name: 'Isabel', category: 'Girls', scoreType: WodScoreType.time, description: '30 snatches, voor tijd.'),
  Wod(name: 'Nancy', category: 'Girls', scoreType: WodScoreType.time, description: '5 ronden: 400m hardlopen, 15 overhead squats.'),
  Wod(name: 'Jackie', category: 'Girls', scoreType: WodScoreType.time, description: '1000m roeien, 50 thrusters, 30 pull-ups.'),
  Wod(name: 'Cindy', category: 'Girls', scoreType: WodScoreType.reps, description: '20 minuten AMRAP: 5 pull-ups, 10 push-ups, 15 air squats.'),
  Wod(name: 'Angie', category: 'Girls', scoreType: WodScoreType.time, description: '100 pull-ups, 100 push-ups, 100 sit-ups, 100 air squats.'),
  Wod(name: 'Elizabeth', category: 'Girls', scoreType: WodScoreType.time, description: '21-15-9 clean en ring dips.'),

  // Hero WODs
  Wod(name: 'Murph', category: 'Hero WODs', scoreType: WodScoreType.time, description: '1 mile hardlopen, 100 pull-ups, 200 push-ups, 300 squats, 1 mile hardlopen.'),
  Wod(name: 'DT', category: 'Hero WODs', scoreType: WodScoreType.time, description: '5 ronden: deadlifts, hang power cleans, push jerks.'),
  Wod(name: 'JT', category: 'Hero WODs', scoreType: WodScoreType.time, description: '21-15-9 handstand push-ups, ring dips, push-ups.'),
  Wod(name: 'Chad', category: 'Hero WODs', scoreType: WodScoreType.time, description: '1000 step-ups met een 45lb plate.'),
  Wod(name: 'Randy', category: 'Hero WODs', scoreType: WodScoreType.time, description: '75 power snatches, voor tijd.'),
  Wod(name: 'Michael', category: 'Hero WODs', scoreType: WodScoreType.time, description: '3 ronden: 800m hardlopen, 50 back extensions, 50 sit-ups.'),
  Wod(name: 'Josh', category: 'Hero WODs', scoreType: WodScoreType.time, description: '21-15-9-15-21 overhead squats en pull-ups.'),
  Wod(name: 'Kalsu', category: 'Hero WODs', scoreType: WodScoreType.time, description: '100 thrusters, elke minuut 5 burpees.'),
];