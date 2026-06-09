import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthInitial());

  Future<void> checkAuth() async {
    state = const AuthLoading();
    // Firebase restores session from cache synchronously
    final user = _repo.getCurrentUser();
    state = user != null
        ? AuthAuthenticated(user: user)
        : const AuthUnauthenticated();
  }

  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      final user = await _repo.signInWithGoogle();
      state = AuthAuthenticated(user: user);
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('sign_in_cancelled')) {
        state = const AuthUnauthenticated();
      } else {
        state = AuthError(msg);
      }
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthUnauthenticated();
  }
}
