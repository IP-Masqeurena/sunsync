import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    setState(() {
      _error = null;
      _busy = true;
    });

    final oldPwd = _oldCtrl.text.trim();
    final newPwd = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (newPwd != confirm) {
      setState(() {
        _error = 'New password and confirmation do not match.';
        _busy = false;
      });
      return;
    }

    final user = _supabase.auth.currentUser;
    final email = user?.email;
    if (email == null) {
      setState(() {
        _error = 'No user logged in.';
        _busy = false;
      });
      return;
    }

    // Re‑authenticate by signing in with old password
    final res = await _supabase.auth.signInWithPassword(
      email: email,
      password: oldPwd,
    );
    if (res.user == null) {
      setState(() {
        _error = 'Old password is incorrect.';
        _busy = false;
      });
      return;
    }

    // Now update to the new password
    final upd = await _supabase.auth.updateUser(
      UserAttributes(password: newPwd),
    );
    if (upd.user == null) {
      setState(() {
        _error = 'Failed to update password.';
        _busy = false;
      });
      return;
    }

    // Success!
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed successfully.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            TextField(
              controller: _oldCtrl,
              decoration: const InputDecoration(labelText: 'Old Password'),
              obscureText: true,
            ),
            TextField(
              controller: _newCtrl,
              decoration: const InputDecoration(labelText: 'New Password'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmCtrl,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _changePassword,
              child: Text(_busy ? 'Changing…' : 'Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
