import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<User?> signUp(String email, String pass) async {
    final res = await supabase.auth.signUp(email: email, password: pass);
    return res.user;
  }

  Future<User?> login(String email, String pass) async {
    final res = await supabase.auth.signInWithPassword(
      email: email, password: pass,
    );
    return res.user;
  }

  Future<void> logout() => supabase.auth.signOut();

  User? get currentUser => supabase.auth.currentUser;
}