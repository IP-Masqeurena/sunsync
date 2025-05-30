import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
  final _subCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  List<File> _images = [];
  List<String> _selectedTags = [];
  bool _busy = false;
  bool _isLandscape = true;
  bool _isPicking = false; // Add this flag


    static const List<String> kAllTags = [
    'examtips','tutoring','food','study','sports','clubs',
    'campuslife','accommodation','emergency','donations',
    'needhelp','events','schorlarships','others',
  ];


  Future<void> _pickImage() async {
    if (_isPicking) return; // Prevent multiple picks
    setState(() => _isPicking = true);
    
    try {
      final img = await _picker.pickImage(source: ImageSource.gallery);
      if (img == null) return;

      final compressed = await FlutterImageCompress.compressAndGetFile(
        img.path,
        '${img.path}_compressed.jpg',
        quality: 50,
        minWidth: 600,
        minHeight: 600,
        autoCorrectionAngle: true,
        keepExif: false,
      );

      if (compressed != null) {
        setState(() => _images.add(File(compressed.path)));
      }
    } finally {
      setState(() => _isPicking = false); // Always reset the flag
    }
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
      orientation: _isLandscape ? 'landscape' : 'portrait',
      tags: _selectedTags,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Orientation Toggle Switch
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: _isLandscape ? 0 : MediaQuery.of(context).size.width / 2 - 20,
                    child: Container(
                      width: MediaQuery.of(context).size.width / 2 - 20,
                      height: 50,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isLandscape = true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Center(
                              child: Text(
                                'Landscape',
                                style: TextStyle(
                                  color: _isLandscape 
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isLandscape = false),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Center(
                              child: Text(
                                'Portrait',
                                style: TextStyle(
                                  color: !_isLandscape 
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Image Picker
            AbsorbPointer(
              absorbing: _isPicking,
              child: Opacity(
                opacity: _isPicking ? 0.5 : 1.0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant, 
                        width: 2
                      )),
                    child: _images.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded,
                                  size: 32, 
                                  color: colorScheme.onSurfaceVariant),
                              const SizedBox(height: 8),
                              Text('Add Photos',
                                  style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _images.length + 1,
                                  itemBuilder: (_, i) {
                                    if (i == _images.length) {
                                      return Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: GestureDetector(
                                          onTap: _pickImage,
                                          child: Container(
                                            width: 100,
                                            decoration: BoxDecoration(
                                              color: colorScheme.surfaceVariant,
                                              borderRadius: BorderRadius.circular(15),
                                            ),
                                            child: Icon(Icons.add,
                                                size: 32, 
                                                color: colorScheme.onSurfaceVariant),
                                          ),
                                        ),
                                      );
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                          left: 12, top: 12, bottom: 12),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(15),
                                            child: Image.file(_images[i],
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () =>
                                                  setState(() => _images.removeAt(i)),
                                              child: const Icon(Icons.cancel, 
                                                color: Colors.red, 
                                                size: 24),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                ),
              ),
            ),
            ),
            const SizedBox(height: 24),

            // Text Fields
            _buildTextField(_titleCtrl, 'Title', colorScheme),
            const SizedBox(height: 16),
            Text('Tags (max 3):', style: TextStyle(fontWeight: FontWeight.w600)),
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
                      if (on && _selectedTags.length < 3) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            _buildTextField(_contentCtrl, 'Content', colorScheme, maxLines: 4),
            const SizedBox(height: 32),

            // Post Button
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                foregroundColor: colorScheme.onPrimary,
                backgroundColor: colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 2,
              ),
              child: Text(
                _busy ? 'Posting...' : 'Post',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    ColorScheme colorScheme, {
    int maxLines = 1
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant, 
            width: 1.5
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.outlineVariant, 
            width: 1.5
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: colorScheme.primary, 
            width: 2
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
            horizontal: 20, vertical: maxLines > 1 ? 16 : 0),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}