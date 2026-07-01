import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client.dart';

class AuthRepository {
  final _auth = SupabaseClientConfig.client.auth;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Session? get currentSession => _auth.currentSession;

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
