import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider((_) => AuthRepository());

// Auth State
sealed class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(AuthInitial()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authenticated = await _repo.isAuthenticated();
    state = authenticated ? AuthAuthenticated() : AuthUnauthenticated();
  }

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      await _repo.login(email, password);
      state = AuthAuthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> register(String email, String username, String password) async {
    state = AuthLoading();
    try {
      await _repo.register(email, username, password);
      // After register, auto-login
      await _repo.login(email, password);
      state = AuthAuthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthUnauthenticated();
  }

  void clearError() {
    if (state is AuthError) state = AuthUnauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
