import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social_post.dart';
import '../models/social_comment.dart';
import '../models/user_profile.dart';
import '../services/social_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/logo_pattern_background.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _navy = Color(0xFF0F1C3F);
const _cardColor = Color(0xFF1B2E5C);

/// Iedereen mag hier posten — vragen, "wie traint er mee", algemeen geklets.
class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = SocialService();

    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        title: const Text('Koffiehoekje'),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      body: Stack(
        children: [
          const LogoPatternBackground(),
          StreamBuilder<UserProfile?>(
            stream: UserProfileService().currentUserProfile,
            builder: (context, profileSnapshot) {
              final isAdmin = profileSnapshot.data?.isAdmin ?? false;

              return StreamBuilder<List<SocialPost>>(
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
                        'Nog geen berichten.\nStel gerust een vraag of zeg hallo!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _cream.withOpacity(0.6)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: posts.length,
                    itemBuilder: (context, index) => _SocialCard(post: posts[index], service: service, isAdmin: isAdmin),
                  );
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _red,
        onPressed: () => _showNewPostSheet(context, service),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showNewPostSheet(BuildContext context, SocialService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      builder: (_) => _NewPostSheet(service: service),
    );
  }
}

class _SocialCard extends StatefulWidget {
  final SocialPost post;
  final SocialService service;
  final bool isAdmin;

  const _SocialCard({required this.post, required this.service, required this.isAdmin});

  @override
  State<_SocialCard> createState() => _SocialCardState();
}

class _SocialCardState extends State<_SocialCard> {
  final _commentController = TextEditingController();
  bool _isSubmittingComment = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmittingComment = true);
    await widget.service.addComment(widget.post.id, text);

    if (!mounted) return;
    _commentController.clear();
    setState(() => _isSubmittingComment = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMine = FirebaseAuth.instance.currentUser?.uid == widget.post.authorUid;

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
                    widget.post.authorNickname,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _cream),
                  ),
                ),
                if (isMine || widget.isAdmin)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: _cream.withOpacity(0.5)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDeletePost(context),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(widget.post.text, style: const TextStyle(fontSize: 14, color: _cream)),
            if (widget.post.isPoll) ...[
              const SizedBox(height: 10),
              _PollView(post: widget.post, service: widget.service),
            ],
            const SizedBox(height: 10),
            Divider(height: 1, color: _cream.withOpacity(0.1)),
            const SizedBox(height: 8),

            StreamBuilder<List<SocialComment>>(
              stream: widget.service.commentsFor(widget.post.id),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? [];

                if (comments.isEmpty) return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: comments.map((comment) => _CommentRow(
                          comment: comment,
                          isAdmin: widget.isAdmin,
                          onDelete: () => widget.service.deleteComment(widget.post.id, comment.id),
                        )).toList(),
                  ),
                );
              },
            ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: _cream, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Schrijf een reactie...',
                      hintStyle: TextStyle(color: _cream.withOpacity(0.4), fontSize: 13),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.06),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                IconButton(
                  icon: _isSubmittingComment
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _cream))
                      : Icon(Icons.send, size: 20, color: _cream.withOpacity(0.7)),
                  onPressed: _isSubmittingComment ? null : _submitComment,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Bericht verwijderen?', style: TextStyle(color: _cream)),
        content: Text(
          'Dit verwijdert jouw bericht. Dit kan niet ongedaan gemaakt worden.',
          style: TextStyle(color: _cream.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuleer', style: TextStyle(color: _cream.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () {
              widget.service.deletePost(widget.post.id);
              Navigator.of(context).pop();
            },
            child: const Text('Verwijder', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  final SocialComment comment;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _CommentRow({required this.comment, required this.isAdmin, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isMine = FirebaseAuth.instance.currentUser?.uid == comment.authorUid;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${comment.authorNickname}  ',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _cream),
                  ),
                  TextSpan(
                    text: comment.text,
                    style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
          ),
          if (isMine || isAdmin)
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close, size: 14, color: _cream.withOpacity(0.4)),
            ),
        ],
      ),
    );
  }
}

class _PollView extends StatelessWidget {
  final SocialPost post;
  final SocialService service;

  const _PollView({required this.post, required this.service});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final myVote = uid != null ? post.voteFor(uid) : null;
    final counts = post.voteCounts;
    final total = post.totalVotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final option in post.pollOptions!)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => service.vote(post.id, option),
              child: Container(
                height: 38,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.06),
                  border: myVote == option ? Border.all(color: _red, width: 1.5) : null,
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: total == 0 ? 0.0 : (counts[option] ?? 0) / total,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _red.withOpacity(0.35),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: const TextStyle(fontSize: 13, color: _cream),
                              ),
                            ),
                            Text(
                              '${counts[option] ?? 0}',
                              style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.7)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Text(
          total == 0 ? 'Nog geen stemmen' : '$total stem${total == 1 ? '' : 'men'}',
          style: TextStyle(fontSize: 11, color: _cream.withOpacity(0.5)),
        ),
      ],
    );
  }
}

class _NewPostSheet extends StatefulWidget {
  final SocialService service;

  const _NewPostSheet({required this.service});

  @override
  State<_NewPostSheet> createState() => _NewPostSheetState();
}

class _NewPostSheetState extends State<_NewPostSheet> {
  final _textController = TextEditingController();
  bool _isSubmitting = false;
  bool _isPoll = false;
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _textController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 6) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int index) {
    setState(() => _optionControllers.removeAt(index).dispose());
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    List<String>? pollOptions;
    if (_isPoll) {
      pollOptions = _optionControllers.map((c) => c.text.trim()).where((o) => o.isNotEmpty).toList();
      if (pollOptions.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vul minstens 2 opties in voor de poll.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    await widget.service.addPost(text, pollOptions: pollOptions);

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
            controller: _textController,
            maxLines: 3,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(
              hintText: _isPoll ? 'Wat wil je vragen?' : 'Bijvoorbeeld: wie traint er vrijdag om 18:00 mee?',
              hintStyle: TextStyle(color: _cream.withOpacity(0.4)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.06),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),

          CheckboxListTile(
            value: _isPoll,
            onChanged: (value) => setState(() => _isPoll = value ?? false),
            title: const Text('Poll toevoegen', style: TextStyle(fontSize: 14, color: _cream)),
            activeColor: _red,
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),

          if (_isPoll) ...[
            for (int i = 0; i < _optionControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionControllers[i],
                        style: const TextStyle(color: _cream),
                        decoration: InputDecoration(
                          hintText: 'Optie ${i + 1}',
                          hintStyle: TextStyle(color: _cream.withOpacity(0.4)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: _cream.withOpacity(0.5)),
                        onPressed: () => _removeOption(i),
                      ),
                  ],
                ),
              ),
            if (_optionControllers.length < 6)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _addOption,
                  child: Text('+ Optie toevoegen', style: TextStyle(color: _cream.withOpacity(0.8))),
                ),
              ),
            const SizedBox(height: 8),
          ],

          const SizedBox(height: 8),

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