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

/// Dữ liệu tài khoản mẫu đồng bộ với seed V6__seed_demo_accounts_and_test_data.sql
class DemoAccount {
  final String identifier;
  final String password;
  final String roleName;
  final String roleDescription;
  final String fullName;
  final String accountId;
  final String memberId;
  final String clanId;
  final List<String> roles;

  const DemoAccount({
    required this.identifier,
    required this.password,
    required this.roleName,
    required this.roleDescription,
    required this.fullName,
    required this.accountId,
    required this.memberId,
    required this.clanId,
    required this.roles,
  });
}

const List<DemoAccount> kDemoAccounts = [
  DemoAccount(
    identifier: '0901234567',
    password: '123456',
    roleName: 'Trưởng Tộc',
    roleDescription: 'Toàn quyền quản trị dòng họ, phê duyệt phiếu thu & bảo vật',
    fullName: 'Nguyễn Trọng Hoàng',
    accountId: 'ACC_TRUONG_TOC',
    memberId: 'MEM_TRUONG_TOC',
    clanId: 'CLAN_DEFAULT',
    roles: ['ROLE_CLAN_HEAD', 'ROLE_MEMBER'],
  ),
  DemoAccount(
    identifier: '0902345678',
    password: '123456',
    roleName: 'Trưởng Chi 2',
    roleDescription: 'Đại diện phân chi họ, quản lý tiếp nhận đóng góp',
    fullName: 'Nguyễn Văn An',
    accountId: 'ACC_TRUONG_CHI',
    memberId: 'MEM_TRUONG_CHI',
    clanId: 'CLAN_DEFAULT',
    roles: ['ROLE_BRANCH_HEAD', 'ROLE_MEMBER'],
  ),
  DemoAccount(
    identifier: '0903888999',
    password: '123456',
    roleName: 'Thành Viên',
    roleDescription: 'Con cháu dòng tộc, tra cứu sổ vàng và biên lai điện tử',
    fullName: 'Nguyễn Thị Mai Anh',
    accountId: 'ACC_MAI_ANH',
    memberId: 'MEM_MAI_ANH',
    clanId: 'CLAN_DEFAULT',
    roles: ['ROLE_MEMBER'],
  ),
];

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
      // Chế độ Offline / Fallback Demo dự phòng khi Backend chưa khởi chạy hoặc mất mạng
      final trimmedIdentifier = loginIdentifier.trim();
      final trimmedPassword = password.trim();

      final matchedDemo = kDemoAccounts.cast<DemoAccount?>().firstWhere(
            (acc) =>
                acc != null &&
                (acc.identifier == trimmedIdentifier ||
                    '${acc.identifier}@gtvn.vn' == trimmedIdentifier) &&
                acc.password == trimmedPassword,
            orElse: () => null,
          );

      if (matchedDemo != null) {
        final demoResponse = AuthTokenResponseDto(
          accessToken: 'demo_jwt_token_${matchedDemo.accountId}',
          refreshToken: 'demo_refresh_token',
          tokenType: 'Bearer',
          expiresIn: 86400,
          accountId: matchedDemo.accountId,
          phoneNumber: matchedDemo.identifier,
          fullName: matchedDemo.fullName,
          roles: matchedDemo.roles,
          clanId: matchedDemo.clanId,
          memberId: matchedDemo.memberId,
        );

        final storage = ref.read(secureTokenStorageProvider);
        await storage.saveAccessToken(demoResponse.accessToken);
        if (demoResponse.clanId != null) {
          await storage.saveActiveClanId(demoResponse.clanId!);
        }

        final roles = demoResponse.roles.map(SystemRole.fromCode).toSet();
        ref.read(dualRbacSessionProvider.notifier).state = DualRbacSession(
          accountId: demoResponse.accountId,
          memberId: demoResponse.memberId ?? '',
          fullName: demoResponse.fullName,
          branchName: 'Chi nhánh gốc (Đại Tôn)',
          globalRoles: roles.isNotEmpty ? roles : {SystemRole.roleMember},
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: demoResponse,
        );
        return;
      }

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
