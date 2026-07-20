import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../models/photo_post.dart';
import '../models/user_profile.dart';
import '../services/photo_service.dart';
import '../services/user_profile_service.dart';
import '../widgets/logo_pattern_background.dart';
import 'photo_detail_screen.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _navy = Color(0xFF0F1C3F);
const _cardColor = Color(0xFF1B2E5C);

/// Coach-only foto-albums: evenementen én het dagelijkse scorebord, apart gehouden.
class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  PhotoCategory _selectedCategory = PhotoCategory.daily;
  final _service = PhotoService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        title: const Text('Foto\'s'),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      body: Stack(
        children: [
          const LogoPatternBackground(),
          StreamBuilder<UserProfile?>(
            stream: UserProfileService().currentUserProfile,
            builder: (context, profileSnapshot) {
              final isCoach = profileSnapshot.data?.isCoach ?? false;
              final isAdmin = profileSnapshot.data?.isAdmin ?? false;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SegmentedButton<PhotoCategory>(
                      segments: const [
                        ButtonSegment(value: PhotoCategory.daily, label: Text('Scores')),
                        ButtonSegment(value: PhotoCategory.event, label: Text('Evenementen')),
                      ],
                      selected: {_selectedCategory},
                      onSelectionChanged: (selection) => setState(() => _selectedCategory = selection.first),
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
                    child: _selectedCategory == PhotoCategory.event
                        ? _EventAlbumsView(service: _service, isAdmin: isAdmin)
                        : StreamBuilder<List<PhotoPost>>(
                            stream: _service.postsFor(_selectedCategory),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'Fout bij laden: ${snapshot.error}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                    ),
                                  ),
                                );
                              }

                              final posts = snapshot.data ?? [];

                              if (posts.isEmpty) {
                                return Center(
                                  child: Text(
                                    'Nog geen foto\'s.',
                                    style: TextStyle(color: _cream.withOpacity(0.6)),
                                  ),
                                );
                              }

                              return _PhotoGrid(posts: posts, service: _service, isAdmin: isAdmin);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<UserProfile?>(
        stream: UserProfileService().currentUserProfile,
        builder: (context, snapshot) {
          if (snapshot.data?.isCoach != true) return const SizedBox.shrink();

          return FloatingActionButton(
            backgroundColor: _red,
            onPressed: () => _showUploadSheet(context),
            child: const Icon(Icons.add_a_photo, color: Colors.white),
          );
        },
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _cardColor,
      builder: (_) => _UploadSheet(service: _service, initialCategory: _selectedCategory),
    );
  }
}

/// Herbruikbaar rooster van foto's — gebruikt voor zowel Scores (platte lijst)
/// als de inhoud van één specifiek evenement-album.
class _PhotoGrid extends StatelessWidget {
  final List<PhotoPost> posts;
  final PhotoService service;
  final bool isAdmin;

  const _PhotoGrid({required this.posts, required this.service, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final canDelete = isAdmin || (FirebaseAuth.instance.currentUser?.uid == post.uid);

        return _PhotoTile(post: post, service: service, canDelete: canDelete);
      },
    );
  }
}

/// Groepeert evenement-foto's op titel (= albumnaam) en toont er een lijst albums van.
class _EventAlbumsView extends StatelessWidget {
  final PhotoService service;
  final bool isAdmin;

  const _EventAlbumsView({required this.service, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PhotoPost>>(
      stream: service.postsFor(PhotoCategory.event),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Fout bij laden: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Text('Nog geen albums.', style: TextStyle(color: _cream.withOpacity(0.6))),
          );
        }

        // Groepeer op titel, posts staan al aflopend op datum, dus de eerste
        // van elke groep is meteen de nieuwste (= cover).
        final albums = <String, List<PhotoPost>>{};
        for (final post in posts) {
          albums.putIfAbsent(post.title, () => []).add(post);
        }

        final albumTitles = albums.keys.toList();

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: albumTitles.length,
          itemBuilder: (context, index) {
            final title = albumTitles[index];
            final albumPosts = albums[title]!;

            return _AlbumTile(title: title, coverPost: albumPosts.first, count: albumPosts.length, posts: albumPosts, service: service, isAdmin: isAdmin);
          },
        );
      },
    );
  }
}

class _AlbumTile extends StatelessWidget {
  final String title;
  final PhotoPost coverPost;
  final int count;
  final List<PhotoPost> posts;
  final PhotoService service;
  final bool isAdmin;

  const _AlbumTile({
    required this.title,
    required this.coverPost,
    required this.count,
    required this.posts,
    required this.service,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _AlbumDetailScreen(title: title, posts: posts, service: service, isAdmin: isAdmin),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    coverPost.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: _cardColor,
                      child: Icon(Icons.broken_image, color: _cream.withOpacity(0.4)),
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                    child: Text('$count', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _cream),
          ),
        ],
      ),
    );
  }
}

class _AlbumDetailScreen extends StatelessWidget {
  final String title;
  final List<PhotoPost> posts;
  final PhotoService service;
  final bool isAdmin;

  const _AlbumDetailScreen({required this.title, required this.posts, required this.service, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      body: _PhotoGrid(posts: posts, service: service, isAdmin: isAdmin),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final PhotoPost post;
  final PhotoService service;
  final bool canDelete;

  const _PhotoTile({required this.post, required this.service, required this.canDelete});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PhotoDetailScreen(post: post, service: service, canDelete: canDelete),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: _cardColor,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: _cardColor,
                  child: Icon(Icons.broken_image, color: _cream.withOpacity(0.4)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            post.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _cream),
          ),
        ],
      ),
    );
  }
}

class _UploadSheet extends StatefulWidget {
  final PhotoService service;
  final PhotoCategory initialCategory;

  const _UploadSheet({required this.service, required this.initialCategory});

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _titleController = TextEditingController();
  late PhotoCategory _selectedCategory;
  final List<File> _selectedImages = [];
  bool _isUploading = false;
  int _uploadedCount = 0;
  String? _errorMessage;
  List<String> _existingAlbumTitles = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _loadExistingAlbums();
  }

  Future<void> _loadExistingAlbums() async {
    final titles = await widget.service.existingEventAlbumTitles();
    if (mounted) setState(() => _existingAlbumTitles = titles);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(
      maxWidth: 1600,
      imageQuality: 70,
    );

    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(picked.map((x) => File(x.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_selectedImages.isEmpty) {
      setState(() => _errorMessage = 'Kies eerst minstens één foto.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vul een titel in.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
    });

    for (final image in _selectedImages) {
      await widget.service.uploadPhoto(
        imageFile: image,
        category: _selectedCategory,
        title: _titleController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _uploadedCount++);
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
          const Text('Nieuwe foto\'s plaatsen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _cream)),
          const SizedBox(height: 16),

          SegmentedButton<PhotoCategory>(
            segments: const [
              ButtonSegment(value: PhotoCategory.daily, label: Text('Scores')),
              ButtonSegment(value: PhotoCategory.event, label: Text('Evenement')),
            ],
            selected: {_selectedCategory},
            onSelectionChanged: (selection) => setState(() => _selectedCategory = selection.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected) ? _red : null;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected) ? Colors.white : _cream;
              }),
            ),
          ),
          const SizedBox(height: 16),

          if (_selectedImages.isNotEmpty) ...[
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return GestureDetector(
                      onTap: _pickImages,
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.add, color: _cream.withOpacity(0.5)),
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_selectedImages[index], width: 90, height: 90, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_selectedImages.length} foto${_selectedImages.length == 1 ? '' : '\'s'} geselecteerd',
              style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.5)),
            ),
            const SizedBox(height: 12),
          ] else
            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: _cream.withOpacity(0.5), size: 32),
                    const SizedBox(height: 6),
                    Text('Kies een of meerdere foto\'s', style: TextStyle(color: _cream.withOpacity(0.5), fontSize: 13)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          TextField(
            controller: _titleController,
            style: const TextStyle(color: _cream),
            decoration: InputDecoration(
              labelText: 'Titel',
              hintText: 'Bijvoorbeeld: Hyrox event 18 juli',
              labelStyle: TextStyle(color: _cream.withOpacity(0.6)),
              hintStyle: TextStyle(color: _cream.withOpacity(0.3)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),

          if (_selectedCategory == PhotoCategory.event && _existingAlbumTitles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Of voeg toe aan een bestaand album:', style: TextStyle(fontSize: 11, color: _cream.withOpacity(0.5))),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _existingAlbumTitles.map((title) {
                return ActionChip(
                  label: Text(title, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.white.withOpacity(0.08),
                  labelStyle: const TextStyle(color: _cream),
                  onPressed: () => setState(() => _titleController.text = title),
                );
              }).toList(),
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
          ],

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: _isUploading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isUploading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text('Bezig... ($_uploadedCount/${_selectedImages.length})'),
                    ],
                  )
                : Text('Plaatsen${_selectedImages.length > 1 ? ' (${_selectedImages.length})' : ''}'),
          ),
        ],
      ),
    );
  }
}