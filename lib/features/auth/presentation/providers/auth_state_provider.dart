import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/rbac_models.dart';
import '../../../../core/storage/secure_token_storage.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/auth_models.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final AuthTokenResponseDto? user;

  const AuthState({
    required this.status,
    this.errorMessage,
    this.user,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    AuthTokenResponseDto? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.initial);
  }

  Future<bool> checkAuthStatus() async {
    final storage = ref.read(secureTokenStorageProvider);
    final token = await storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(status: AuthStatus.authenticated);
      return true;
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return false;
    }
  }

  Future<void> login(String loginIdentifier, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final dataSource = ref.read(authRemoteDataSourceProvider);
      final response = await dataSource.login(LoginRequestDto(
        loginIdentifier: loginIdentifier,
        password: password,
      ));

      final storage = ref.read(secureTokenStorageProvider);
      await storage.saveAccessToken(response.accessToken);
      if (response.clanId != null) {
        await storage.saveActiveClanId(response.clanId!);
      }

      // Synchronize Dual-RBAC session
      final roles = response.roles.map(SystemRole.fromCode).toSet();
      ref.read(dualRbacSessionProvider.notifier).state = DualRbacSession(
        accountId: response.accountId,
        memberId: response.memberId ?? '',
        fullName: response.fullName,
        branchName: response.clanId != null ? 'Dòng họ ${response.clanId}' : 'Chi nhánh gốc',
        globalRoles: roles.isNotEmpty ? roles : {SystemRole.roleMember},
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: response,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> registerCreator(RegisterCreatorRequestDto request) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final dataSource = ref.read(authRemoteDataSourceProvider);
      await dataSource.registerCreator(request);

      // Auto login right after registration
      await login(request.phoneNumber, request.password);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<void> logout() async {
    final storage = ref.read(secureTokenStorageProvider);
    await storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authStateProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
