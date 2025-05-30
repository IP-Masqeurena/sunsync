// lib/pages/edit_post_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_services.dart';

class EditPostPage extends StatefulWidget {
  final Map<String, dynamic> post;
  const EditPostPage({required this.post, Key? key}) : super(key: key);

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _svc = PostService();
  final _picker = ImagePicker();

  final _titleCtrl   = TextEditingController();
  final _subCtrl     = TextEditingController();
  final _contentCtrl = TextEditingController();

  bool _busy = false;
  bool _isLandscape = true;
  List<String> _selectedTags = [];
  late List<String> _existingUrls;
  final List<File> _newImages = [];
  static const List<String> kAllTags = [
    'examtips','tutoring','food','study','sports','clubs',
    'campuslife','accommodation','emergency','donations',
    'needhelp','events','schorlarships','others',
  ];
  static const int _maxImages = 3;

  @override
  void initState() {
    super.initState();
    final p = widget.post;
    _titleCtrl.text   = p['title'] as String;
    _subCtrl.text     = p['subtitle'] as String? ?? '';
    _contentCtrl.text = p['content'] as String?  ?? '';
    _isLandscape      = (p['orientation'] as String? ?? 'landscape') == 'landscape';
    _selectedTags = List<String>.from(p['tags'] ?? []);
    _existingUrls = List<String>.from(p['image_urls'] ?? []);
  }

Future<void> _pickImage() async {
  if (_existingUrls.length + _newImages.length >= _maxImages) {
    return _showMaxImagesAlert();
  }

  // 1) Pick an XFile
  final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
  if (picked == null) return;

  // 2) Compress into an XFile? (some versions return XFile)
  final XFile? compressedX = await FlutterImageCompress.compressAndGetFile(
    picked.path,
    '${picked.path}_cmp.jpg',
    quality: 85,
  ); // cast to XFile?

  // 3) Convert to dart:io File
  final File toAdd = File(compressedX?.path ?? picked.path);

  setState(() {
    _newImages.add(toAdd);
  });
}

  void _showMaxImagesAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Too many images'),
        content: Text('You can only have up to $_maxImages images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _removeImage({String? url, File? file}) {
    setState(() {
      if (url != null) _existingUrls.remove(url);
      if (file != null) _newImages.remove(file);
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);

    // 1) Upload new images via service
    final newUrls = <String>[];
    for (var i = 0; i < _newImages.length; i++) {
      final url = await _svc.uploadImage(
        image: _newImages[i],
        userId: widget.post['user_id'] as String,
        index: i,
      );
      newUrls.add(url);
    }

    // 2) Merge
    final finalUrls = [..._existingUrls, ...newUrls];

    // 3) Update
    await _svc.updatePost(
      postId: widget.post['id'] as String,
      title: _titleCtrl.text.trim(),
      subtitle: _subCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      orientation: _isLandscape ? 'landscape' : 'portrait',
      imageUrls: finalUrls,
      tags: _selectedTags,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Orientation
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Landscape'),
                  selected: _isLandscape,
                  onSelected: (_) => setState(() => _isLandscape = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Portrait'),
                  selected: !_isLandscape,
                  onSelected: (_) => setState(() => _isLandscape = false),
                ),
              ],
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
 Text('Tags (max 3):', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: kAllTags.map((tag) {
                final selected = _selectedTags.contains(tag);
                return ChoiceChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (on) {
                    setState(() {
                      if (on && _selectedTags.length < 3) _selectedTags.add(tag);
                      else _selectedTags.remove(tag);
                    });
                  },
                );
              }).toList(),
            ),
            TextField(
              controller: _contentCtrl,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
            ),

            const SizedBox(height: 20),
            Text('Images (max $_maxImages):', style: theme.titleMedium),
            const SizedBox(height: 8),

            // Thumbnails + add tile
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var url in _existingUrls)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          url,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeImage(url: url),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                for (var file in _newImages)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(
                          file,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeImage(file: file),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                if (_existingUrls.length + _newImages.length < _maxImages)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Saving…' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
