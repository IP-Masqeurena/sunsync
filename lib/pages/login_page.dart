import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/theme_notifier.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();

  bool _busy = false;
  String? _emailError;
  String? _passError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _emailError = null;
      _passError = null;
    });

    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    try {
      final user = await _auth.login(email, pass);
      if (user == null) {
        setState(() {
          _emailError = 'Unknown Error';
          _passError = 'Unknown Error';
          _passCtrl.clear();
          _busy = false;
        });
        return;
      }
          final profile = await Supabase.instance.client
        .from('userdata')
        .select('banner_choice')
        .eq('id', user.id)
        .single();
    final choice = (profile as Map<String, dynamic>)['banner_choice'] as String?;

    // Apply it immediately via your ThemeNotifier
    Provider.of<ThemeNotifier>(context, listen: false)
        .setBannerChoice(choice);
    // ────────────────────────────────────────────────────────────────────

      // success
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _emailError = 'Incorrect email or password.';
        _passError = 'Incorrect email or password.';
        _passCtrl.clear();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _emailError,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: _passError,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _login,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Login'),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupPage()),
                      );
                    },
              child: const Text('Don\'t have an account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}