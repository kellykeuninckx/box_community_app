import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/news_post.dart';
import '../models/user_profile.dart';
import '../services/news_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/logo_pattern_background.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _navy = Color(0xFF0F1C3F);
const _cardColor = Color(0xFF1B2E5C);

/// Alleen admins (een subset van de coaches) posten hier — officiële berichten,
/// nieuwsbrief, verloren voorwerpen. Iedereen kan lezen.
class NewsFeedScreen extends StatelessWidget {
  const NewsFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = NewsService();
    final profileService = UserProfileService();

    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        title: const Text('Nieuws'),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      body: Stack(
        children: [
          const LogoPatternBackground(),
          StreamBuilder<List<NewsPost>>(
            stream: service.posts,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Fout bij laden: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                );
              }

              final posts = snapshot.data ?? [];

              if (posts.isEmpty) {
                return Center(
                  child: Text(
                    'Nog geen nieuwsberichten.',
                    style: TextStyle(color: _cream.withOpacity(0.6)),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: posts.length,
                itemBuilder: (context, index) => _NewsCard(post: posts[index], service: service),
              );
            },
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<UserProfile?>(
        stream: profileService.currentUserProfile,
        builder: (context, snapshot) {
          if (snapshot.data?.isAdmin != true) return const SizedBox.shrink();

          return FloatingActionButton(
            backgroundColor: _red,
            onPressed: () => _showNewPostSheet(context, service),
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  void _showNewPostSheet(BuildContext context, NewsService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      builder: (_) => _NewPostSheet(service: service),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsPost post;
  final NewsService service;

  const _NewsCard({required this.post, required this.service});

  @override
  Widget build(BuildContext context) {
    final isMine = FirebaseAuth.instance.currentUser?.uid == post.authorUid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _cream),
                  ),
                ),
                if (isMine)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: _cream.withOpacity(0.5)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDelete(context),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(post.body, style: const TextStyle(fontSize: 14, color: _cream)),
            const SizedBox(height: 8),
            Text(
              '— ${post.authorNickname}',
              style: TextStyle(fontSize: 11, color: _cream.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Bericht verwijderen?', style: TextStyle(color: _cream)),
        content: Text(
          'Dit verwijdert dit nieuwsbericht. Dit kan niet ongedaan gemaakt worden.',
          style: TextStyle(color: _cream.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuleer', style: TextStyle(color: _cream.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () {
              service.deletePost(post.id);
              Navigator.of(context).pop();
            },
            child: const Text('Verwijder', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
  }
}

class _NewPostSheet extends StatefulWidget {
  final NewsService service;

  const _NewPostSheet({required this.service});

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    await widget.service.addPost(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
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
          const Text('Nieuw bericht', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _cream)),
          const SizedBox(height: 16),

          TextField(
            controller: _titleController,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(
              labelText: 'Titel',
              labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _bodyController,
            maxLines: 4,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(
              labelText: 'Bericht',
              labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
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
                : const Text('Plaatsen'),
          ),
        ],
      ),
    );
  }
}