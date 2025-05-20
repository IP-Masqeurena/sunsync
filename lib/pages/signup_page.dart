import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'details_page.dart';

class SignupPage extends StatefulWidget { const SignupPage({super.key});
  @override _SPState createState() => _SPState();
}
class _SPState extends State<SignupPage> {
  final eCtrl = TextEditingController(), pCtrl = TextEditingController();
  bool busy = false;
  final auth = AuthService();
  Future<void> next() async {
    setState(()=>busy=true);
    final user = await auth.signUp(eCtrl.text.trim(), pCtrl.text.trim());
    setState(()=>busy=false);
    if (user!=null) Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_)=> DetailsPage(uid: user.id)),
    );
  }
  @override Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('Sign Up – 1')),
    body: Padding(padding: const EdgeInsets.all(16), child: Column(children:[
      TextField(controller: eCtrl, decoration: const InputDecoration(labelText:'Email')),  
      TextField(controller: pCtrl, decoration: const InputDecoration(labelText:'Password'), obscureText:true),
      const SizedBox(height:24),
      ElevatedButton(onPressed: busy?null:next, child: Text(busy?'...':'Next'))
    ])));
}