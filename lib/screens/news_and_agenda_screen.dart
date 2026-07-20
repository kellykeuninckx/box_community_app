import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/news_post.dart';
import '../models/agenda_event.dart';
import '../models/user_profile.dart';
import '../services/news_service.dart';
import '../services/agenda_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/logo_pattern_background.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _navy = Color(0xFF0F1C3F);
const _cardColor = Color(0xFF1B2E5C);

const _weekdays = ['maandag', 'dinsdag', 'woensdag', 'donderdag', 'vrijdag', 'zaterdag', 'zondag'];
const _months = ['januari', 'februari', 'maart', 'april', 'mei', 'juni', 'juli', 'augustus', 'september', 'oktober', 'november', 'december'];

String _formatDutchDate(DateTime date, {bool withYear = false}) {
  final weekday = _weekdays[date.weekday - 1];
  final month = _months[date.month - 1];
  final year = withYear ? ' ${date.year}' : '';
  return '$weekday ${date.day} $month$year';
}

class NewsAndAgendaScreen extends StatefulWidget {
  const NewsAndAgendaScreen({super.key});

  @override
  State<NewsAndAgendaScreen> createState() => _NewsAndAgendaScreenState();
}

class _NewsAndAgendaScreenState extends State<NewsAndAgendaScreen> {
  bool _showAgenda = false;
  final _newsService = NewsService();
  final _agendaService = AgendaService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        title: const Text('Nieuws & Agenda'),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      body: StreamBuilder<UserProfile?>(
        stream: UserProfileService().currentUserProfile,
        builder: (context, profileSnapshot) {
          final isAdmin = profileSnapshot.data?.isAdmin ?? false;

          return Stack(
            children: [
              const LogoPatternBackground(),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Nieuws')),
                        ButtonSegment(value: true, label: Text('Agenda')),
                      ],
                      selected: {_showAgenda},
                      onSelectionChanged: (selection) => setState(() => _showAgenda = selection.first),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          return states.contains(WidgetState.selected) ? _red : null;
                        }),
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          return states.contains(WidgetState.selected) ? Colors.white : _cream;
                        }),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _showAgenda
                        ? _AgendaBody(service: _agendaService, isAdmin: isAdmin)
                        : _NewsBody(service: _newsService, isAdmin: isAdmin),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      floatingActionButton: StreamBuilder<UserProfile?>(
        stream: UserProfileService().currentUserProfile,
        builder: (context, snapshot) {
          if (snapshot.data?.isAdmin != true) return const SizedBox.shrink();

          return FloatingActionButton(
            backgroundColor: _red,
            onPressed: () => _showAgenda
                ? _showNewAgendaSheet(context)
                : _showNewNewsSheet(context),
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  void _showNewNewsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      builder: (_) => _NewNewsSheet(service: _newsService),
    );
  }

  void _showNewAgendaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      builder: (_) => _NewAgendaSheet(service: _agendaService),
    );
  }
}

// MARK: - Nieuws

class _NewsBody extends StatelessWidget {
  final NewsService service;
  final bool isAdmin;

  const _NewsBody({required this.service, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<NewsPost>>(
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
            child: Text('Nog geen nieuwsberichten.', style: TextStyle(color: _cream.withOpacity(0.6))),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          itemBuilder: (context, index) => _NewsCard(post: posts[index], service: service, isAdmin: isAdmin),
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsPost post;
  final NewsService service;
  final bool isAdmin;

  const _NewsCard({required this.post, required this.service, required this.isAdmin});

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
                  child: Text(post.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _cream)),
                ),
                if (isMine || isAdmin) ...[
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 18, color: _cream.withOpacity(0.5)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showEditSheet(context),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: _cream.withOpacity(0.5)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(post.body, style: const TextStyle(fontSize: 14, color: _cream)),
            const SizedBox(height: 8),
            Text('— ${post.authorNickname}', style: TextStyle(fontSize: 11, color: _cream.withOpacity(0.5))),
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
        content: Text('Dit kan niet ongedaan gemaakt worden.', style: TextStyle(color: _cream.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Annuleer', style: TextStyle(color: _cream.withOpacity(0.7)))),
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

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      builder: (_) => _NewNewsSheet(service: service, existingPost: post),
    );
  }
}

class _NewNewsSheet extends StatefulWidget {
  final NewsService service;
  final NewsPost? existingPost;

  const _NewNewsSheet({required this.service, this.existingPost});

  @override
  State<_NewNewsSheet> createState() => _NewNewsSheetState();
}

class _NewNewsSheetState extends State<_NewNewsSheet> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingPost != null) {
      _titleController.text = widget.existingPost!.title;
      _bodyController.text = widget.existingPost!.body;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    if (widget.existingPost != null) {
      await widget.service.updatePost(widget.existingPost!.id, title: _titleController.text.trim(), body: _bodyController.text.trim());
    } else {
      await widget.service.addPost(title: _titleController.text.trim(), body: _bodyController.text.trim());
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existingPost != null ? 'Bericht bewerken' : 'Nieuw bericht',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _cream),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(labelText: 'Titel', labelStyle: TextStyle(color: _cream.withOpacity(0.6)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(labelText: 'Bericht', labelStyle: TextStyle(color: _cream.withOpacity(0.6)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.existingPost != null ? 'Opslaan' : 'Plaatsen'),
          ),
        ],
      ),
    );
  }
}

// MARK: - Agenda

class _AgendaBody extends StatelessWidget {
  final AgendaService service;
  final bool isAdmin;

  const _AgendaBody({required this.service, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AgendaEvent>>(
      stream: service.upcomingEvents,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Fout bij laden: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Text('Nog geen aankomende events.', style: TextStyle(color: _cream.withOpacity(0.6))),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: events.length,
          itemBuilder: (context, index) => _AgendaCard(event: events[index], service: service, isAdmin: isAdmin),
        );
      },
    );
  }
}

class _AgendaCard extends StatelessWidget {
  final AgendaEvent event;
  final AgendaService service;
  final bool isAdmin;

  const _AgendaCard({required this.event, required this.service, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final isMine = FirebaseAuth.instance.currentUser?.uid == event.authorUid;
    final formattedDate = _formatDutchDate(event.eventDate);

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
                  decoration: BoxDecoration(color: _cream, borderRadius: BorderRadius.circular(6)),
                  child: Text(formattedDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _navy)),
                ),
                const Spacer(),
                if (isMine || isAdmin) ...[
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 18, color: _cream.withOpacity(0.5)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showEditSheet(context),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: _cream.withOpacity(0.5)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDelete(context),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(event.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _cream)),
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(event.description, style: const TextStyle(fontSize: 14, color: _cream)),
            ],
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
        title: const Text('Event verwijderen?', style: TextStyle(color: _cream)),
        content: Text('Dit kan niet ongedaan gemaakt worden.', style: TextStyle(color: _cream.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Annuleer', style: TextStyle(color: _cream.withOpacity(0.7)))),
          TextButton(
            onPressed: () {
              service.deleteEvent(event.id);
              Navigator.of(context).pop();
            },
            child: const Text('Verwijder', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      builder: (_) => _NewAgendaSheet(service: service, existingEvent: event),
    );
  }
}

class _NewAgendaSheet extends StatefulWidget {
  final AgendaService service;
  final AgendaEvent? existingEvent;

  const _NewAgendaSheet({required this.service, this.existingEvent});

  @override
  State<_NewAgendaSheet> createState() => _NewAgendaSheetState();
}

class _NewAgendaSheetState extends State<_NewAgendaSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.existingEvent != null) {
      _titleController.text = widget.existingEvent!.title;
      _descriptionController.text = widget.existingEvent!.description;
      _selectedDate = widget.existingEvent!.eventDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vul een titel in.');
      return;
    }

    setState(() => _isSubmitting = true);

    if (widget.existingEvent != null) {
      await widget.service.updateEvent(
        widget.existingEvent!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: _selectedDate,
      );
    } else {
      await widget.service.addEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        eventDate: _selectedDate,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.existingEvent != null ? 'Event bewerken' : 'Nieuw event',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _cream),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today, size: 18, color: _cream),
            label: Text(
              _formatDutchDate(_selectedDate, withYear: true),
              style: const TextStyle(color: _cream),
            ),
            style: OutlinedButton.styleFrom(side: BorderSide(color: _cream.withOpacity(0.4)), padding: const EdgeInsets.symmetric(vertical: 12)),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _titleController,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(labelText: 'Titel', hintText: 'Bijvoorbeeld: Hyrox event', labelStyle: TextStyle(color: _cream.withOpacity(0.6)), hintStyle: TextStyle(color: _cream.withOpacity(0.3)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descriptionController,
            maxLines: 3,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(labelText: 'Beschrijving (optioneel)', labelStyle: TextStyle(color: _cream.withOpacity(0.6)), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
          ],

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.existingEvent != null ? 'Opslaan' : 'Plaatsen'),
          ),
        ],
      ),
    );
  }
}