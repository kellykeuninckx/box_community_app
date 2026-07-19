import 'package:flutter/material.dart';
import '../models/wod.dart';
import 'wod_detail_screen.dart';
import '../widgets/logo_pattern_background.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _navy = Color(0xFF0F1C3F);

class WodListScreen extends StatefulWidget {
  const WodListScreen({super.key});

  @override
  State<WodListScreen> createState() => _WodListScreenState();
}

class _WodListScreenState extends State<WodListScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = benchmarkWods
        .where((w) => w.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final girls = filtered.where((w) => w.category == 'Girls').toList();
    final heroes = filtered.where((w) => w.category == 'Hero WODs').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benchmark WODs'),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      backgroundColor: _navy,
      body: Stack(
        children: [
          const LogoPatternBackground(),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  style: const TextStyle(color: _cream),
                  decoration: InputDecoration(
                    hintText: 'Zoek een WOD...',
                    hintStyle: TextStyle(color: _cream.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.search, color: _cream.withOpacity(0.6)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    if (girls.isNotEmpty) ..._section('Girls', girls, context),
                    if (heroes.isNotEmpty) ..._section('Hero WODs', heroes, context),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text('Geen WOD gevonden.', style: TextStyle(color: _cream.withOpacity(0.6))),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _section(String title, List<Wod> wods, BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _red),
        ),
      ),
      ...wods.map((wod) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(wod.name, style: const TextStyle(fontWeight: FontWeight.w600, color: _cream)),
              subtitle: Text(
                wod.lines.first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: _cream.withOpacity(0.55)),
              ),
              trailing: Icon(Icons.chevron_right, color: _cream.withOpacity(0.5)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => WodDetailScreen(wod: wod)),
              ),
            ),
          )),
    ];
  }
}