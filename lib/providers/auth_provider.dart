
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:followup/models/user_model.dart';
import 'package:followup/services/auth_service.dart';


final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateChangesProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.userChanges.map((user) => user);
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthController(authService, ref);
});

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _authService;
  // Kept for future use with other providers
  final Ref ref;

  AuthController(this._authService, this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final currentUser = await _authService.getCurrentUser();
      state = AsyncValue.data(currentUser);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithEmailAndPassword(email, password);
      state = AsyncValue.data(user);
      return user;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
    UserRole role,
  ) async {
    state = const AsyncValue.loading();
    try {
      UserModel? user;
      switch (role) {
        case UserRole.parent:
          user = await _authService.registerParent(email, password, name);
          break;
        case UserRole.sheikh:
          // For sheikh, we need additional parameters
          throw UnimplementedError('Sheikh registration not implemented');
        case UserRole.admin:
          throw Exception('Admin registration is not allowed');
      }
      if (user != null) {
        state = AsyncValue.data(user);
      } else {
        throw Exception('Failed to register user');
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _authService.resetPassword(email);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}
