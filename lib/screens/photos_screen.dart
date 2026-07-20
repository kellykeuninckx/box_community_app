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
  PhotoCategory _selectedCategory = PhotoCategory.event;
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
                        ButtonSegment(value: PhotoCategory.event, label: Text('Evenementen')),
                        ButtonSegment(value: PhotoCategory.daily, label: Text('Dagelijks bord')),
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
                    child: StreamBuilder<List<PhotoPost>>(
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
                              'Nog geen foto\'s in dit album.',
                              style: TextStyle(color: _cream.withOpacity(0.6)),
                            ),
                          );
                        }

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
                            final canDelete = isAdmin ||
                                (FirebaseAuth.instance.currentUser?.uid == post.uid);

                            return _PhotoTile(post: post, service: _service, canDelete: canDelete);
                          },
                        );
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
  File? _selectedImage;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 70,
    );

    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    if (_selectedImage == null) {
      setState(() => _errorMessage = 'Kies eerst een foto.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vul een titel in.');
      return;
    }

    setState(() => _isUploading = true);

    await widget.service.uploadPhoto(
      imageFile: _selectedImage!,
      category: _selectedCategory,
      title: _titleController.text.trim(),
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
          const Text('Nieuwe foto plaatsen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _cream)),
          const SizedBox(height: 16),

          SegmentedButton<PhotoCategory>(
            segments: const [
              ButtonSegment(value: PhotoCategory.event, label: Text('Evenement')),
              ButtonSegment(value: PhotoCategory.daily, label: Text('Dagelijks bord')),
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

          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: _cream.withOpacity(0.5), size: 32),
                        const SizedBox(height: 6),
                        Text('Kies een foto', style: TextStyle(color: _cream.withOpacity(0.5), fontSize: 13)),
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