import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/bottom_nav.dart';

class DetailsPage extends StatefulWidget {
  final String uid;
  const DetailsPage({required this.uid, super.key});
  @override _DPState createState() => _DPState();
}
class _DPState extends State<DetailsPage> {
  final picker = ImagePicker(); File? photo;
  bool isUnder = true, saving = false;
  final us = UserService();
  final ctrls = {
    'full_name': TextEditingController(),
    'student_id': TextEditingController(),
    'age': TextEditingController(),
    'grad_year': TextEditingController(),
    'course': TextEditingController(),
    'department': TextEditingController(),
    'occupation': TextEditingController(),
  };

  Future pick() async {
    final p = await picker.pickImage(source:ImageSource.gallery,imageQuality:80);
    if (p != null) setState(()=>photo = File(p.path));
  }

  Future submit() async {
    setState(()=>saving=true);
    String? url;
    if (photo != null) url = await us.uploadAvatar(widget.uid, photo!);

    final data = {
      'email': AuthService().currentUser!.email,
      'full_name': ctrls['full_name']!.text.trim(),
      'student_id': ctrls['student_id']!.text.trim(),
      'age': int.tryParse(ctrls['age']!.text.trim()),
      'grad_year': int.tryParse(ctrls['grad_year']!.text.trim()),
      'course': ctrls['course']!.text.trim(),
      'department': ctrls['department']!.text.trim(),
      'occupation': ctrls['occupation']!.text.trim(),
      'is_undergrad': isUnder,
      if (url != null) 'avatar_url': url,
    };
    await us.saveDetails(widget.uid, data);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder:(_)=> const BottomNav()), (_) => false,
    );
  }

  @override Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Sign Up – 2')),
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children:[
      GestureDetector(onTap: pick, child: CircleAvatar(
        radius:50, backgroundImage: photo!=null?FileImage(photo!):null,
        child: photo==null? const Icon(Icons.camera_alt,size:40):null,
      )),
      const SizedBox(height:16),
      ToggleButtons(isSelected: [isUnder,!isUnder], onPressed: (i)=> setState(()=>isUnder = i==0), children:[
        const Padding(padding: EdgeInsets.all(8), child:Text('Undergrad')),
        const Padding(padding: EdgeInsets.all(8), child:Text('Postgrad'))
      ]),
      const SizedBox(height:16),
      for(final e in ctrls.entries)...[
        TextField(controller: e.value, decoration: InputDecoration(labelText: e.key.replaceAll('_',' ').toUpperCase())),
        const SizedBox(height:12)
      ],
      const SizedBox(height:24),
      ElevatedButton(onPressed: saving?null:submit, child: Text(saving?'Saving...':'Sign Up'))
    ])));
}