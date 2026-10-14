import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/common/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/fcm_service.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final FCMService _fcmService = FCMService();

  bool isRegistrationInProgress = false;
  bool _isLoggingOut = false;

  void setRegistrationInProgress(bool value) {
    isRegistrationInProgress = value;
  }

  AuthNotifier(this._repository) : super(AuthInitial()) {
    _init();
  }

  void _init() {
    _repository.watchAuthState().listen((user) async {
      if (isRegistrationInProgress) {
        // Do not interrupt the active registration flow, do not update state, do not trigger router rebuilds
        return;
      }

      if (user == null) {
        if (!_isLoggingOut) {
          state = Unauthenticated();
        }
      } else {
        if (_isLoggingOut) return;

        if (user.status == 'blocked' || user.status == 'deleted') {
          await _repository.signOut();
          state = AuthError(
            user.status == 'deleted'
                ? 'هذا الحساب محذوف.'
                : 'تم حظر هذا الحساب من قبل إدارة رحال ولا يمكن تسجيل الدخول.',
          );
          return;
        }

        if (user.role == 'driver' && user.status != 'approved') {
          if (user.status == 'registering' ||
              user.status == 'pending_review' ||
              user.status == 'need_modification') {
            state = Authenticated(user);
            return;
          }
          await _repository.signOut();
          if (user.status == 'rejected') {
            state = const AuthError('REDIRECT:/rejected-account');
          } else {
            state = const AuthError('حسابك غير مفعل بعد.');
          }
          return;
        }

        final isNewLogin =
            state is! Authenticated ||
            (state as Authenticated).user.id != user.id;
        state = Authenticated(user);
        if (isNewLogin) {
          await _fcmService.saveTokenToDatabase(user.id);
          await _fcmService.subscribeToRoleTopic(user.role);
          try {
            await FirebaseFirestore.instance.collection('audit_logs').add({
              'targetUid': user.id,
              'actorUid': user.id,
              'actorRole': user.role,
              'action': 'تسجيل الدخول',
              'description': 'تسجيل دخول المستخدم',
              'timestamp': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            // Ignore audit log error so login proceeds
          }
        }
      }
    });
  }

  Future<void> login(String phone, String password) async {
    state = AuthLoading();
    try {
      final user = await _repository.signIn(phone, password);
      if (user == null) {
        if (!_isLoggingOut) state = Unauthenticated();
      }
      // Note: If user != null, the watchAuthState stream will automatically emit
      // the new user and update the state to Authenticated.
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<UserModel?> register({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    Map<String, dynamic>? roleFields,
  }) async {
    state = AuthLoading();
    try {
      final user = await _repository.signUp(
        fullName: fullName,
        phone: phone,
        password: password,
        role: role,
        roleFields: roleFields,
      );
      if (user == null) {
        state = Unauthenticated();
      }
      return user;
    } catch (e) {
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
      rethrow;
    }
  }

  Future<UserModel?> registerDriver({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    return register(
      fullName: name,
      phone: phone,
      password: password,
      role: 'driver',
      roleFields: {'email': email},
    );
  }

  Future<UserModel?> registerCompany({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    return register(
      fullName: name,
      phone: phone,
      password: password,
      role: 'company',
      roleFields: {'email': email},
    );
  }

  Future<void> logout() async {
    if (_isLoggingOut) return;
    final currentState = state;
    _isLoggingOut = true;
    state = AuthLoading();
    try {
      if (currentState is Authenticated) {
        try {
          await _fcmService.unsubscribeFromRoleTopic(currentState.user.role);
          await _fcmService.clearToken(currentState.user.id);
        } catch (e) {
          // ignore
        }
        try {
          await FirebaseFirestore.instance.collection('audit_logs').add({
            'targetUid': currentState.user.id,
            'actorUid': currentState.user.id,
            'actorRole': currentState.user.role,
            'action': 'تسجيل الخروج',
            'description': 'تسجيل خروج المستخدم',
            'timestamp': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          // Ignore audit log error so logout proceeds
        }
      }
      await _repository.signOut();
      _isLoggingOut = false;
      state = Unauthenticated();
    } catch (e) {
      _isLoggingOut = false;
      state = AuthError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
