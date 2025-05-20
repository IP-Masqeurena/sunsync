import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/post_services.dart';

class PostingPage extends StatefulWidget {
  final String userId;
  const PostingPage({required this.userId, Key? key}) : super(key: key);
  @override
  State<PostingPage> createState() => _PostingPageState();
}

class _PostingPageState extends State<PostingPage> {
  final _postSvc = PostService();
  final _picker = ImagePicker();
  final _titleCtrl = TextEditingController();
  final _subCtrl   = TextEditingController();
  final _contentCtrl = TextEditingController();
  List<File> _images = [];
  bool _busy = false;
  bool _isLandscape = true; // NEW: orientation flag

  Future<void> _pickImage() async {
    final img = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) setState(() => _images.add(File(img.path)));
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.isEmpty || _images.isEmpty) return;
    setState(() => _busy = true);
    await _postSvc.addPost(
      userId: widget.userId,
      title: _titleCtrl.text.trim(),
      subtitle: _subCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      images: _images,
      orientation: _isLandscape ? 'landscape' : 'portrait', // pass choice
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Orientation selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Landscape'),
                  selected: _isLandscape,
                  onSelected: (sel) => setState(() => _isLandscape = true),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Portrait'),
                  selected: !_isLandscape,
                  onSelected: (sel) => setState(() => _isLandscape = false),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Image picker + previews
            GestureDetector(
              onTap: _pickImage,
              child: _images.isEmpty
                ? Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Center(child: Icon(Icons.add_photo_alternate, size: 48)),
                  )
                : SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length + 1,
                      itemBuilder: (_, i) {
                        if (i == _images.length) {
                          return IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _pickImage,
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Image.file(_images[i], width: 150, height: 150, fit: BoxFit.cover),
                              Positioned(
                                top: 4, right: 4,
                                child: GestureDetector(
                                  onTap: () => setState(() => _images.removeAt(i)),
                                  child: const Icon(Icons.cancel, color: Colors.red, size: 24),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
            ),
            const SizedBox(height: 16),

            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: _subCtrl, decoration: const InputDecoration(labelText: 'Subtitle')),
            const SizedBox(height: 12),
            TextField(
              controller: _contentCtrl,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              child: Text(_busy ? 'Posting…' : 'Post'),
            ),
          ],
        ),
      ),
    );
  }
}
