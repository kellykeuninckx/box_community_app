import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/photo_post.dart';
import '../services/photo_service.dart';

const _cream = Color(0xFFF0EDC8);
const _red = Color(0xFF8B1E2B);
const _navy = Color(0xFF0F1C3F);
const _cardColor = Color(0xFF1B2E5C);

class PhotoDetailScreen extends StatefulWidget {
  final PhotoPost post;
  final PhotoService service;
  final bool canDelete;

  const PhotoDetailScreen({super.key, required this.post, required this.service, required this.canDelete});

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  bool _isDownloading = false;

  Future<void> _download() async {
    setState(() => _isDownloading = true);

    try {
      final response = await http.get(Uri.parse(widget.post.imageUrl));
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/foto_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloaden is niet gelukt. Probeer het opnieuw.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardColor,
        title: const Text('Foto verwijderen?', style: TextStyle(color: _cream)),
        content: Text(
          'Dit verwijdert de foto definitief. Dit kan niet ongedaan gemaakt worden.',
          style: TextStyle(color: _cream.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Annuleer', style: TextStyle(color: _cream.withOpacity(0.7))),
          ),
          TextButton(
            onPressed: () {
              widget.service.deletePhoto(widget.post);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Verwijder', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        title: Text(widget.post.title),
        backgroundColor: _navy,
        foregroundColor: _cream,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Image.network(widget.post.imageUrl, fit: BoxFit.contain),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Geplaatst door ${widget.post.nickname}',
                  style: TextStyle(fontSize: 12, color: _cream.withOpacity(0.6)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _download,
                        icon: _isDownloading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.download),
                        label: Text(_isDownloading ? 'Bezig...' : 'Downloaden'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (widget.canDelete) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: _confirmDelete,
                        icon: Icon(Icons.delete_outline, color: _cream.withOpacity(0.7)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}