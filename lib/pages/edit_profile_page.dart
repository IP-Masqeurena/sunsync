import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class EditProfilePage extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> existingData;
  const EditProfilePage({required this.uid, required this.existingData, super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _picker = ImagePicker();
  File? _photo;
  bool _isUnder = true, _saving = false;
  final _userSvc = UserService();
  late final Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    // initialize controllers with existing values
    _ctrls = {
      'full_name': TextEditingController(text: widget.existingData['full_name']),
      'student_id': TextEditingController(text: widget.existingData['student_id']),
      'age': TextEditingController(text: widget.existingData['age']?.toString()),
      'grad_year': TextEditingController(text: widget.existingData['grad_year']?.toString()),
      'course': TextEditingController(text: widget.existingData['course']),
      'department': TextEditingController(text: widget.existingData['department']),
      'occupation': TextEditingController(text: widget.existingData['occupation']),
    };
    _isUnder = widget.existingData['is_undergrad'] ?? true;
  }

  @override
  void dispose() {
    for (var c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    // if they picked a new photo, upload it
    String? avatarUrl = widget.existingData['avatar_url'];
    if (_photo != null) {
      final url = await _userSvc.uploadAvatar(widget.uid, _photo!);
      avatarUrl = url ?? avatarUrl;
    }

    // build updated data map
    final updated = {
      'full_name': _ctrls['full_name']!.text.trim(),
      'student_id': _ctrls['student_id']!.text.trim(),
      'age': int.tryParse(_ctrls['age']!.text.trim()),
      'grad_year': int.tryParse(_ctrls['grad_year']!.text.trim()),
      'course': _ctrls['course']!.text.trim(),
      'department': _ctrls['department']!.text.trim(),
      'occupation': _ctrls['occupation']!.text.trim(),
      'is_undergrad': _isUnder,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };

    await _userSvc.saveDetails(widget.uid, updated);
    setState(() => _saving = false);
    Navigator.of(context).pop(); // return to profile
  }

  @override
  Widget build(BuildContext context) {
    final existingUrl = widget.existingData['avatar_url'] as String?;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: _photo != null
                  ? FileImage(_photo!)
                  : (existingUrl != null ? NetworkImage(existingUrl) : null) as ImageProvider<Object>?,
              child: _photo == null && existingUrl == null
                  ? const Icon(Icons.camera_alt, size: 40)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          ToggleButtons(
            isSelected: [_isUnder, !_isUnder],
            onPressed: (i) => setState(() => _isUnder = (i == 0)),
            children: const [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Undergrad')),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Postgrad')),
            ],
          ),
          const SizedBox(height: 16),
          for (final entry in {
            'Full Name': 'full_name',
            'Student ID': 'student_id',
            'Age': 'age',
            'Year of Graduation': 'grad_year',
            'Course': 'course',
            'Department': 'department',
            'Occupation': 'occupation',
          }.entries) ...[
            TextField(
              controller: _ctrls[entry.value],
              decoration: InputDecoration(labelText: entry.key),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ]),
      ),
    );
  }
}
