import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wall_of_fame_post.dart';
import '../services/wall_of_fame_service.dart';

class WallOfFameScreen extends StatelessWidget {
  const WallOfFameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = WallOfFameService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<WallOfFamePost>>(
        stream: service.posts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Er ging iets mis: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(
              child: Text(
                'Nog geen prestaties gedeeld.\nWees de eerste!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return _PostCard(post: posts[index], service: service);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B1E2B),
        onPressed: () => _showNewPostSheet(context, service),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showNewPostSheet(BuildContext context, WallOfFameService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _NewPostSheet(service: service),
    );
  }
}

class _PostCard extends StatelessWidget {
  final WallOfFamePost post;
  final WallOfFameService service;

  const _PostCard({required this.post, required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E2B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    post.type,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B1E2B),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  post.authorNickname,
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(post.text, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            Row(
              children: post.reactionCounts.entries.map((entry) {
                final emoji = entry.key;
                final count = entry.value;
                final uid = FirebaseAuth.instance.currentUser?.uid;
                final isMine = uid != null && post.reactionFor(uid) == emoji;

                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    onTap: () => service.toggleReaction(post.id, emoji),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMine
                            ? const Color(0xFF8B1E2B).withOpacity(0.15)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: isMine
                            ? Border.all(color: const Color(0xFF8B1E2B), width: 1)
                            : null,
                      ),
                      child: Text(
                        '$emoji $count',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewPostSheet extends StatefulWidget {
  final WallOfFameService service;

  const _NewPostSheet({required this.service});

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _textController = TextEditingController();
  String _selectedType = 'Eerste keer';
  bool _isSubmitting = false;

  static const _types = ['Eerste keer', 'Nieuw record', 'Mijlpaal'];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_textController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    await widget.service.addPost(
      type: _selectedType,
      text: _textController.text.trim(),
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
            'Nieuwe prestatie delen',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            children: _types.map((type) {
              final isSelected = type == _selectedType;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                selectedColor: const Color(0xFF8B1E2B),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                ),
                onSelected: (_) => setState(() => _selectedType = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _textController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Bijvoorbeeld: eerste toes-to-bar! 🎉',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

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
                : const Text('Delen'),
          ),
        ],
      ),
    );
  }
}