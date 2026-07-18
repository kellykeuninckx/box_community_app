import 'package:flutter/material.dart';
import '../models/wod.dart';
import 'wod_detail_screen.dart';

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
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Zoek een WOD...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.black.withOpacity(0.04),
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
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Center(child: Text('Geen WOD gevonden.')),
                  ),
              ],
            ),
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
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF8B1E2B),
          ),
        ),
      ),
      ...wods.map((wod) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(wod.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                wod.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => WodDetailScreen(wod: wod)),
              ),
            ),
          )),
    ];
  }
}