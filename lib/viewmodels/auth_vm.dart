
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_exception.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'providers.dart';

class AuthState {
  final UserModel? user;
  final bool loading;
  final String? error;
  final Map<String, String> fieldErrors;

  const AuthState({
    this.user,
    this.loading = false,
    this.error,
    this.fieldErrors = const {},
  });
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> restoreSession() async {
    try {
      final user = await _repo.restoreSession();
      state = AuthState(user: user);
      return user != null;
    } on ApiException catch (e) {
      state = AuthState(error: e.message);
      return false;
    }
  }

  Future<bool> login(String email, String password) =>
      _run(() => _repo.login(email: email, password: password));

  Future<bool> register(
    String name,
    String email,
    String password,
    String confirm,
  ) =>
      _run(() => _repo.register(
            name: name,
            email: email,
            password: password,
            passwordConfirmation: confirm,
          ));

  /// Mengambil profil terbaru dari Laravel API.
  Future<bool> loadProfile() async {
    if (state.loading) return false;

    state = AuthState(user: state.user, loading: true);

    try {
      final user = await _repo.getProfile();
      state = AuthState(user: user);
      return true;
    } on ApiException catch (e) {
      state = AuthState(user: state.user, error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  void clearError() {
    if (state.error != null || state.fieldErrors.isNotEmpty) {
      state = AuthState(user: state.user);
    }
  }

  Future<bool> _run(Future<UserModel> Function() action) async {
    if (state.loading) return false;

    state = AuthState(user: state.user, loading: true);

    try {
      final user = await action();
      state = AuthState(user: user);
      return true;
    } on ApiException catch (e) {
      state = AuthState(
        error: e.message,
        fieldErrors: e.fieldErrors,
      );
      return false;
    }
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
