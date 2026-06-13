# Product and Auth Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the mock login and mock-driven product entry points with real Supabase login, backend profile loading, and backend-backed product flows while preserving the current `ChangeNotifier` architecture.

**Architecture:** Introduce an auth feature that composes Supabase sign-in with backend profile fetch, let `SessionController` own the authenticated session, extend `ApiClient` with a shared bearer-token provider, and rewire customer/admin product screens to existing product use cases and controllers instead of `ProductMockStore`.

**Tech Stack:** Flutter, `ChangeNotifier`, `supabase_flutter`, custom `ApiClient` over `dart:io`, backend REST API at `/api/v1`, Flutter unit/widget tests.

---

## File Structure Map

### New files

- `lib/app/di/auth_module.dart`
  - Wires auth data sources, repository, and use cases.
- `lib/core/network/auth_token_provider.dart`
  - Shared typedef for bearer-token lookup.
- `lib/features/auth/data/datasources/supabase_auth_data_source.dart`
  - Wraps Supabase login, restore, and logout calls.
- `lib/features/auth/data/datasources/auth_profile_remote_data_source.dart`
  - Fetches `GET /users/profile` from backend.
- `lib/features/auth/data/models/auth_profile_model.dart`
  - Maps backend profile payload to `AppUser`.
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
  - Composes Supabase session and backend profile fetch.
- `lib/features/auth/domain/entities/auth_session.dart`
  - Domain object containing `AppUser` plus access token.
- `lib/features/auth/domain/repositories/auth_repository.dart`
  - Auth contract for login, restore, and logout.
- `lib/features/auth/domain/usecases/login_usecase.dart`
  - Login orchestration entry point.
- `lib/features/auth/domain/usecases/logout_usecase.dart`
  - Logout orchestration entry point.
- `lib/features/auth/domain/usecases/restore_session_usecase.dart`
  - Restores an existing Supabase session and loads backend profile.
- `lib/features/product/presentation/cubit/product_home_controller.dart`
  - Dedicated controller for featured products on the customer home page.
- `test/app/config/app_config_test.dart`
  - Covers config derivation and validation.
- `test/core/network/api_client_test.dart`
  - Covers bearer-header injection and error mapping.
- `test/features/auth/data/repositories/auth_repository_impl_test.dart`
  - Covers auth repository composition logic.
- `test/features/auth/presentation/pages/login_page_test.dart`
  - Covers login loading and error states.
- `test/features/product/presentation/cubit/product_catalog_controller_test.dart`
  - Covers public-list filtering and pagination state.
- `test/features/product/presentation/cubit/product_home_controller_test.dart`
  - Covers featured-product loading, filtering, and error state.
- `test/features/product/presentation/cubit/product_management_controller_test.dart`
  - Covers CRUD/status orchestration and list reloads.
- `test/features/product/presentation/pages/product_home_page_test.dart`
  - Covers customer home loading/error/empty state wiring.
- `test/features/product/presentation/pages/product_management_page_test.dart`
  - Covers admin/pegawai role gating with the real controller.
- `test/shared/services/session_controller_test.dart`
  - Covers session login, restore, logout, and error behavior.

### Modified files

- `pubspec.yaml`
  - Add `supabase_flutter`.
- `lib/app/config/app_config.dart`
  - Move to an instance-based runtime config sourced from `dart-define`.
- `lib/main.dart`
  - Initialize Supabase, create `AppConfig`, construct `SessionController`, and pass shared token provider into modules.
- `lib/core/network/api_client.dart`
  - Add optional bearer-token injection.
- `lib/shared/models/app_user.dart`
  - Expand user fields to match backend profile.
- `lib/shared/services/session_controller.dart`
  - Replace demo login with real auth-session state handling.
- `lib/features/auth/presentation/pages/login_page.dart`
  - Drive real login through `SessionController`, with loading and error states.
- `lib/app/di/product_module.dart`
  - Accept runtime config and token provider; create product management controller per page.
- `lib/app/di/cart_module.dart`
  - Accept runtime config and token provider.
- `lib/app/di/order_module.dart`
  - Accept runtime config and token provider.
- `lib/app/di/payment_module.dart`
  - Accept runtime config and token provider.
- `lib/app/di/admin_module.dart`
  - Accept runtime config and token provider.
- `lib/app/router/app_shell_page.dart`
  - Pass `ProductModule` to admin shell path as well as customer path.
- `lib/features/admin/presentation/pages/admin_dashboard_page.dart`
  - Open product management with a real controller from `ProductModule`.
- `lib/features/product/presentation/cubit/product_catalog_controller.dart`
  - Remove seed/mock path from main flow and preserve customer visibility rules.
- `lib/features/product/presentation/pages/product_home_page.dart`
  - Replace `ProductMockStore` with `ProductHomeController`.
- `lib/features/product/presentation/pages/product_catalog_page.dart`
  - Stop injecting `mockProducts` from the main flow.
- `lib/features/product/presentation/pages/product_detail_page.dart`
  - Add retry-capable error state.
- `lib/features/product/presentation/pages/product_management_page.dart`
  - Remove the mock controller and bind to `ProductManagementController`.

### Existing reference files to keep open while implementing

- `docs/superpowers/specs/2026-06-05-product-auth-integration-design.md`
- `lib/core/errors/app_exception.dart`
- `lib/features/product/data/datasources/product_remote_data_source.dart`
- `lib/features/product/data/repositories/product_repository_impl.dart`
- `lib/features/product/domain/entities/product_query.dart`
- `lib/features/product/domain/entities/upsert_product_input.dart`

## Task 1: Add Runtime Config and Supabase Dependency

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/app/config/app_config.dart`
- Test: `test/app/config/app_config_test.dart`

- [ ] **Step 1: Write the failing config test**

```dart
import 'package:cafe/app/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds API base URLs from backend origin', () {
    const config = AppConfig(
      backendOrigin: 'http://10.0.2.2:8080',
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon-key',
    );

    expect(config.apiBaseUrl, 'http://10.0.2.2:8080/api/v1');
    expect(config.productBaseUrl, config.apiBaseUrl);
    expect(config.orderBaseUrl, config.apiBaseUrl);
    expect(config.paymentBaseUrl, config.apiBaseUrl);
    expect(config.adminBaseUrl, config.apiBaseUrl);
  });

  test('validate throws when required Supabase config is missing', () {
    expect(
      () => const AppConfig(
        backendOrigin: 'http://10.0.2.2:8080',
        supabaseUrl: '',
        supabaseAnonKey: '',
      ).validate(),
      throwsStateError,
    );
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```powershell
flutter test test/app/config/app_config_test.dart -r expanded
```

Expected:

```text
FAIL ... AppConfig isn't constructible with backendOrigin/supabaseUrl/supabaseAnonKey
```

- [ ] **Step 3: Write the minimal implementation**

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  shared_preferences: ^2.5.3
  supabase_flutter: ^2.14.0
  url_launcher: ^6.3.1
```

```dart
class AppConfig {
  const AppConfig({
    required this.backendOrigin,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  const AppConfig.fromEnvironment()
      : backendOrigin = String.fromEnvironment(
          'BACKEND_ORIGIN',
          defaultValue: 'http://10.0.2.2:8080',
        ),
        supabaseUrl = String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  final String backendOrigin;
  final String supabaseUrl;
  final String supabaseAnonKey;

  String get apiBaseUrl => '$backendOrigin/api/v1';
  String get productBaseUrl => apiBaseUrl;
  String get orderBaseUrl => apiBaseUrl;
  String get paymentBaseUrl => apiBaseUrl;
  String get adminBaseUrl => apiBaseUrl;

  void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be provided via --dart-define.',
      );
    }
  }
}
```

- [ ] **Step 4: Run dependency resolution and the config test**

Run:

```powershell
flutter pub get
flutter test test/app/config/app_config_test.dart -r expanded
```

Expected:

```text
Resolving dependencies...
Got dependencies!
00:00 +2: All tests passed!
```

- [ ] **Step 5: Commit**

```powershell
git add pubspec.yaml pubspec.lock lib/app/config/app_config.dart test/app/config/app_config_test.dart
git commit -m "build: add runtime app config"
```

## Task 2: Build the Auth Repository and Auth Session Types

**Files:**
- Create: `lib/features/auth/domain/entities/auth_session.dart`
- Create: `lib/features/auth/domain/repositories/auth_repository.dart`
- Create: `lib/features/auth/domain/usecases/login_usecase.dart`
- Create: `lib/features/auth/domain/usecases/logout_usecase.dart`
- Create: `lib/features/auth/domain/usecases/restore_session_usecase.dart`
- Create: `lib/features/auth/data/datasources/supabase_auth_data_source.dart`
- Create: `lib/features/auth/data/datasources/auth_profile_remote_data_source.dart`
- Create: `lib/features/auth/data/models/auth_profile_model.dart`
- Create: `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Modify: `lib/shared/models/app_user.dart`
- Test: `test/features/auth/data/repositories/auth_repository_impl_test.dart`

- [ ] **Step 1: Write the failing repository test**

```dart
import 'package:cafe/core/errors/app_exception.dart';
import 'package:cafe/features/auth/data/datasources/auth_profile_remote_data_source.dart';
import 'package:cafe/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:cafe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSupabaseAuthDataSource implements SupabaseAuthDataSource {
  _FakeSupabaseAuthDataSource({this.loginToken, this.restoredToken});

  final String? loginToken;
  final String? restoredToken;
  bool signOutCalled = false;

  @override
  Future<String> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (loginToken == null) {
      throw const AppException('Invalid login credentials');
    }
    return loginToken!;
  }

  @override
  Future<String?> getPersistedAccessToken() async => restoredToken;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

class _FakeAuthProfileRemoteDataSource implements AuthProfileRemoteDataSource {
  _FakeAuthProfileRemoteDataSource(this.profile);

  final AppUser profile;
  String? lastToken;

  @override
  Future<AppUser> getMyProfile(String accessToken) async {
    lastToken = accessToken;
    return profile;
  }
}

void main() {
  const profile = AppUser(
    id: 'user-1',
    email: 'admin@cafe.local',
    fullName: 'Admin Cafe',
    role: UserRole.admin,
    isVerified: true,
    isActive: true,
    phoneNumber: '+628123456789',
    avatarUrl: 'https://example.com/avatar.png',
  );

  test('login composes Supabase token and backend profile into one auth session',
      () async {
    final repository = AuthRepositoryImpl(
      supabaseAuthDataSource: _FakeSupabaseAuthDataSource(loginToken: 'token-123'),
      authProfileRemoteDataSource: _FakeAuthProfileRemoteDataSource(profile),
    );

    final session = await repository.login(
      email: 'admin@cafe.local',
      password: '12345678',
    );

    expect(session.accessToken, 'token-123');
    expect(session.user.fullName, 'Admin Cafe');
    expect(session.user.role, UserRole.admin);
  });

  test('restoreSession returns null when Supabase has no persisted token', () async {
    final repository = AuthRepositoryImpl(
      supabaseAuthDataSource: _FakeSupabaseAuthDataSource(restoredToken: null),
      authProfileRemoteDataSource: _FakeAuthProfileRemoteDataSource(profile),
    );

    final session = await repository.restoreSession();

    expect(session, isNull);
  });
}
```

- [ ] **Step 2: Run the repository test to verify it fails**

Run:

```powershell
flutter test test/features/auth/data/repositories/auth_repository_impl_test.dart -r expanded
```

Expected:

```text
FAIL ... SupabaseAuthDataSource/AuthRepositoryImpl/AppUser fields do not exist yet
```

- [ ] **Step 3: Write the minimal auth data/domain implementation**

```dart
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isVerified,
    required this.isActive,
    this.phoneNumber,
    this.avatarUrl,
  });

  const AppUser.guest()
      : id = '',
        email = '',
        fullName = 'Guest',
        role = UserRole.customer,
        isVerified = false,
        isActive = false,
        phoneNumber = null,
        avatarUrl = null;

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final String? phoneNumber;
  final String? avatarUrl;

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    bool? isVerified,
    bool? isActive,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

extension UserRoleX on UserRole {
  static UserRole fromApiValue(String value) {
    switch (value) {
      case 'Admin':
        return UserRole.admin;
      case 'Pegawai':
        return UserRole.pegawai;
      case 'Customer':
      default:
        return UserRole.customer;
    }
  }
}
```

```dart
import 'package:cafe/shared/models/app_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.user,
  });

  final String accessToken;
  final AppUser user;
}
```

```dart
import 'package:cafe/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AuthSession?> restoreSession();

  Future<void> logout();
}
```

```dart
import 'package:cafe/features/auth/domain/entities/auth_session.dart';
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
```

```dart
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() {
    return _repository.logout();
  }
}
```

```dart
import 'package:cafe/features/auth/domain/entities/auth_session.dart';
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';

class RestoreSessionUseCase {
  const RestoreSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession?> call() {
    return _repository.restoreSession();
  }
}
```

```dart
import 'package:cafe/shared/models/app_user.dart';

abstract class SupabaseAuthDataSource {
  Future<String> signInWithPassword({
    required String email,
    required String password,
  });

  Future<String?> getPersistedAccessToken();

  Future<void> signOut();
}

abstract class AuthProfileRemoteDataSource {
  Future<AppUser> getMyProfile(String accessToken);
}
```

```dart
import 'package:cafe/core/errors/app_exception.dart';
import 'package:cafe/features/auth/data/datasources/auth_profile_remote_data_source.dart';
import 'package:cafe/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:cafe/features/auth/domain/entities/auth_session.dart';
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required SupabaseAuthDataSource supabaseAuthDataSource,
    required AuthProfileRemoteDataSource authProfileRemoteDataSource,
  })  : _supabaseAuthDataSource = supabaseAuthDataSource,
        _authProfileRemoteDataSource = authProfileRemoteDataSource;

  final SupabaseAuthDataSource _supabaseAuthDataSource;
  final AuthProfileRemoteDataSource _authProfileRemoteDataSource;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final accessToken = await _supabaseAuthDataSource.signInWithPassword(
      email: email,
      password: password,
    );
    final user = await _authProfileRemoteDataSource.getMyProfile(accessToken);
    return AuthSession(accessToken: accessToken, user: user);
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final accessToken = await _supabaseAuthDataSource.getPersistedAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }
    final user = await _authProfileRemoteDataSource.getMyProfile(accessToken);
    return AuthSession(accessToken: accessToken, user: user);
  }

  @override
  Future<void> logout() async {
    try {
      await _supabaseAuthDataSource.signOut();
    } on AppException {
      rethrow;
    }
  }
}
```

```dart
import 'package:cafe/shared/models/app_user.dart';

class AuthProfileModel {
  const AuthProfileModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isVerified,
    required this.isActive,
    this.phoneNumber,
    this.avatarUrl,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool isVerified;
  final bool isActive;
  final String? phoneNumber;
  final String? avatarUrl;

  factory AuthProfileModel.fromJson(Map<String, dynamic> json) {
    return AuthProfileModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      role: UserRoleX.fromApiValue(json['role'] as String? ?? 'Customer'),
      isVerified: json['is_verified'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  AppUser toEntity() {
    return AppUser(
      id: id,
      email: email,
      fullName: fullName,
      role: role,
      isVerified: isVerified,
      isActive: isActive,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
    );
  }
}
```

- [ ] **Step 4: Run the repository test to verify it passes**

Run:

```powershell
flutter test test/features/auth/data/repositories/auth_repository_impl_test.dart -r expanded
```

Expected:

```text
00:00 +2: All tests passed!
```

- [ ] **Step 5: Commit**

```powershell
git add lib/shared/models/app_user.dart lib/features/auth/data lib/features/auth/domain test/features/auth/data/repositories/auth_repository_impl_test.dart
git commit -m "feat: add auth repository foundation"
```

## Task 3: Wire SessionController, Login Page, and App Bootstrap

**Files:**
- Create: `lib/app/di/auth_module.dart`
- Modify: `lib/shared/services/session_controller.dart`
- Modify: `lib/features/auth/presentation/pages/login_page.dart`
- Modify: `lib/main.dart`
- Test: `test/shared/services/session_controller_test.dart`
- Test: `test/features/auth/presentation/pages/login_page_test.dart`

- [ ] **Step 1: Write failing session and login-page tests**

```dart
import 'package:cafe/core/errors/app_exception.dart';
import 'package:cafe/features/auth/domain/entities/auth_session.dart';
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';
import 'package:cafe/features/auth/domain/usecases/login_usecase.dart';
import 'package:cafe/features/auth/domain/usecases/logout_usecase.dart';
import 'package:cafe/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthRepository implements AuthRepository {
  AuthSession? loginResult;
  AuthSession? restoreResult;
  Object? loginError;
  bool logoutCalled = false;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    if (loginError != null) throw loginError!;
    return loginResult!;
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<AuthSession?> restoreSession() async => restoreResult;
}

void main() {
  const user = AppUser(
    id: 'user-1',
    email: 'customer@cafe.local',
    fullName: 'Customer Cafe',
    role: UserRole.customer,
    isVerified: true,
    isActive: true,
    phoneNumber: null,
    avatarUrl: null,
  );

  test('loginWithCredentials stores user and access token', () async {
    final repository = _FakeAuthRepository()
      ..loginResult = const AuthSession(accessToken: 'token-123', user: user);
    final controller = SessionController(
      loginUseCase: LoginUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      restoreSessionUseCase: RestoreSessionUseCase(repository),
    );

    await controller.loginWithCredentials(
      email: 'customer@cafe.local',
      password: '12345678',
    );

    expect(controller.isLoggedIn, isTrue);
    expect(controller.accessToken, 'token-123');
    expect(controller.currentUser.fullName, 'Customer Cafe');
  });

  test('restoreSession keeps app logged out when repository returns null', () async {
    final repository = _FakeAuthRepository()..restoreResult = null;
    final controller = SessionController(
      loginUseCase: LoginUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      restoreSessionUseCase: RestoreSessionUseCase(repository),
    );

    await controller.restoreSession();

    expect(controller.isLoggedIn, isFalse);
    expect(controller.currentUser.fullName, 'Guest');
  });

  test('loginWithCredentials exposes error message from AppException', () async {
    final repository = _FakeAuthRepository()
      ..loginError = const AppException('Account disabled', code: 'ACCOUNT_DISABLED');
    final controller = SessionController(
      loginUseCase: LoginUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      restoreSessionUseCase: RestoreSessionUseCase(repository),
    );

    await expectLater(
      controller.loginWithCredentials(
        email: 'customer@cafe.local',
        password: '12345678',
      ),
      throwsA(isA<AppException>()),
    );

    expect(controller.errorMessage, 'Account disabled');
    expect(controller.isLoggedIn, isFalse);
  });
}
```

```dart
import 'dart:async';

import 'package:cafe/features/auth/domain/entities/auth_session.dart';
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';
import 'package:cafe/features/auth/domain/usecases/login_usecase.dart';
import 'package:cafe/features/auth/domain/usecases/logout_usecase.dart';
import 'package:cafe/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:cafe/features/auth/presentation/pages/login_page.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CompletingAuthRepository implements AuthRepository {
  _CompletingAuthRepository(this._completer);

  final Completer<AuthSession> _completer;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) {
    return _completer.future;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restoreSession() async => null;
}

void main() {
  testWidgets('shows loading indicator while login request is running', (tester) async {
    final completer = Completer<AuthSession>();
    final repository = _CompletingAuthRepository(completer);
    final controller = SessionController(
      loginUseCase: LoginUseCase(repository),
      logoutUseCase: LogoutUseCase(repository),
      restoreSessionUseCase: RestoreSessionUseCase(repository),
    );

    await tester.pumpWidget(
      MaterialApp(home: LoginPage(sessionController: controller)),
    );

    await tester.enterText(find.byType(TextField).at(0), 'customer@cafe.local');
    await tester.enterText(find.byType(TextField).at(1), '12345678');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(
      const AuthSession(
        accessToken: 'token-123',
        user: AppUser(
          id: 'user-1',
          email: 'customer@cafe.local',
          fullName: 'Customer Cafe',
          role: UserRole.customer,
          isVerified: true,
          isActive: true,
          phoneNumber: null,
          avatarUrl: null,
        ),
      ),
    );
  });
}
```

- [ ] **Step 2: Run the session and login-page tests to verify they fail**

Run:

```powershell
flutter test test/shared/services/session_controller_test.dart -r expanded
flutter test test/features/auth/presentation/pages/login_page_test.dart -r expanded
```

Expected:

```text
FAIL ... SessionController constructor does not accept use cases yet
FAIL ... LoginPage does not render loading state from SessionController yet
```

- [ ] **Step 3: Write the minimal session/bootstrap implementation**

```dart
import 'package:cafe/features/auth/domain/usecases/login_usecase.dart';
import 'package:cafe/features/auth/domain/usecases/logout_usecase.dart';
import 'package:cafe/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter/foundation.dart';

class SessionController extends ChangeNotifier {
  SessionController({
    required LoginUseCase loginUseCase,
    required LogoutUseCase logoutUseCase,
    required RestoreSessionUseCase restoreSessionUseCase,
  })  : _loginUseCase = loginUseCase,
        _logoutUseCase = logoutUseCase,
        _restoreSessionUseCase = restoreSessionUseCase;

  final LoginUseCase _loginUseCase;
  final LogoutUseCase _logoutUseCase;
  final RestoreSessionUseCase _restoreSessionUseCase;

  AppUser _currentUser = const AppUser.guest();
  String? _accessToken;
  bool _isLoggedIn = false;
  bool _isAuthenticating = false;
  bool _isRestoring = false;
  String? _errorMessage;

  AppUser get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAuthenticating => _isAuthenticating;
  bool get isRestoring => _isRestoring;
  String? get errorMessage => _errorMessage;

  Future<void> loginWithCredentials({
    required String email,
    required String password,
  }) async {
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _loginUseCase(email: email, password: password);
      _currentUser = session.user;
      _accessToken = session.accessToken;
      _isLoggedIn = true;
    } catch (error) {
      _currentUser = const AppUser.guest();
      _accessToken = null;
      _isLoggedIn = false;
      _errorMessage = '$error'.replaceFirst('AppException(code: null, statusCode: null, message: ', '').replaceFirst(')', '');
      rethrow;
    } finally {
      _isAuthenticating = false;
      notifyListeners();
    }
  }

  Future<void> restoreSession() async {
    _isRestoring = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _restoreSessionUseCase();
      if (session == null) {
        _currentUser = const AppUser.guest();
        _accessToken = null;
        _isLoggedIn = false;
        return;
      }
      _currentUser = session.user;
      _accessToken = session.accessToken;
      _isLoggedIn = true;
    } catch (_) {
      _currentUser = const AppUser.guest();
      _accessToken = null;
      _isLoggedIn = false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _logoutUseCase();
    } finally {
      _currentUser = const AppUser.guest();
      _accessToken = null;
      _isLoggedIn = false;
      _errorMessage = null;
      notifyListeners();
    }
  }
}
```

```dart
import 'package:cafe/app/config/app_config.dart';
import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/auth/data/datasources/auth_profile_remote_data_source.dart';
import 'package:cafe/features/auth/data/datasources/supabase_auth_data_source.dart';
import 'package:cafe/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cafe/features/auth/domain/usecases/login_usecase.dart';
import 'package:cafe/features/auth/domain/usecases/logout_usecase.dart';
import 'package:cafe/features/auth/domain/usecases/restore_session_usecase.dart';

class AuthModule {
  AuthModule({required AppConfig config})
      : _repository = AuthRepositoryImpl(
          supabaseAuthDataSource: SupabaseAuthDataSourceImpl(),
          authProfileRemoteDataSource: AuthProfileRemoteDataSourceImpl(
            ApiClient(baseUrl: config.apiBaseUrl),
          ),
        );

  final AuthRepositoryImpl _repository;

  LoginUseCase get loginUseCase => LoginUseCase(_repository);
  LogoutUseCase get logoutUseCase => LogoutUseCase(_repository);
  RestoreSessionUseCase get restoreSessionUseCase => RestoreSessionUseCase(_repository);
}
```

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthDataSourceImpl implements SupabaseAuthDataSource {
  SupabaseAuthDataSourceImpl({GoTrueClient? authClient})
      : _authClient = authClient ?? Supabase.instance.client.auth;

  final GoTrueClient _authClient;

  @override
  Future<String?> getPersistedAccessToken() async {
    return _authClient.currentSession?.accessToken;
  }

  @override
  Future<String> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await _authClient.signInWithPassword(
      email: email,
      password: password,
    );
    return response.session!.accessToken;
  }

  @override
  Future<void> signOut() {
    return _authClient.signOut();
  }
}
```

```dart
import 'package:cafe/core/network/api_client.dart';
import 'package:cafe/features/auth/data/models/auth_profile_model.dart';
import 'package:cafe/shared/models/app_user.dart';

class AuthProfileRemoteDataSourceImpl implements AuthProfileRemoteDataSource {
  AuthProfileRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AppUser> getMyProfile(String accessToken) async {
    final response = await _apiClient.get(
      '/users/profile',
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );
    final data = response['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return AuthProfileModel.fromJson(data).toEntity();
  }
}
```

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const config = AppConfig.fromEnvironment();
  config.validate();

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  final authModule = AuthModule(config: config);
  final sessionController = SessionController(
    loginUseCase: authModule.loginUseCase,
    logoutUseCase: authModule.logoutUseCase,
    restoreSessionUseCase: authModule.restoreSessionUseCase,
  )..restoreSession();

  final productModule = ProductModule(
    config: config,
    authTokenProvider: () => sessionController.accessToken,
  );
  final cartModule = CartModule(
    config: config,
    authTokenProvider: () => sessionController.accessToken,
  );
  final orderModule = OrderModule(
    config: config,
    authTokenProvider: () => sessionController.accessToken,
  );
  final paymentModule = PaymentModule(
    config: config,
    authTokenProvider: () => sessionController.accessToken,
  );
  final adminModule = AdminModule(
    config: config,
    authTokenProvider: () => sessionController.accessToken,
  );

  runApp(
    CafeApp(
      productModule: productModule,
      cartModule: cartModule,
      orderModule: orderModule,
      paymentModule: paymentModule,
      adminModule: adminModule,
      sessionController: sessionController,
    ),
  );
}
```

```dart
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: widget.sessionController.isAuthenticating ? null : _handleLogin,
    child: widget.sessionController.isAuthenticating
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Text('Masuk'),
  ),
),
if (widget.sessionController.errorMessage != null) ...[
  const SizedBox(height: 10),
  Text(
    widget.sessionController.errorMessage!,
    style: const TextStyle(color: Colors.red),
  ),
]
```

- [ ] **Step 4: Run the session and login-page tests to verify they pass**

Run:

```powershell
flutter test test/shared/services/session_controller_test.dart -r expanded
flutter test test/features/auth/presentation/pages/login_page_test.dart -r expanded
```

Expected:

```text
00:00 +3: All tests passed!
00:00 +1: All tests passed!
```

- [ ] **Step 5: Commit**

```powershell
git add lib/app/di/auth_module.dart lib/shared/services/session_controller.dart lib/features/auth/presentation/pages/login_page.dart lib/main.dart test/shared/services/session_controller_test.dart test/features/auth/presentation/pages/login_page_test.dart
git commit -m "feat: integrate auth session flow"
```

## Task 4: Add Shared Bearer-Token Plumbing and Rewire Modules

**Files:**
- Create: `lib/core/network/auth_token_provider.dart`
- Modify: `lib/core/network/api_client.dart`
- Modify: `lib/app/di/product_module.dart`
- Modify: `lib/app/di/cart_module.dart`
- Modify: `lib/app/di/order_module.dart`
- Modify: `lib/app/di/payment_module.dart`
- Modify: `lib/app/di/admin_module.dart`
- Modify: `lib/app/router/app_shell_page.dart`
- Modify: `lib/features/admin/presentation/pages/admin_dashboard_page.dart`
- Modify: `lib/main.dart`
- Test: `test/core/network/api_client_test.dart`

- [ ] **Step 1: Write the failing API client test**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:cafe/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('attaches bearer token when token provider returns a token', () async {
    late String? authorizationHeader;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    server.listen((request) async {
      authorizationHeader = request.headers.value(HttpHeaders.authorizationHeader);
      request.response
        ..statusCode = 200
        ..write(jsonEncode(<String, dynamic>{'success': true, 'data': <String, dynamic>{}}));
      await request.response.close();
    });

    final client = ApiClient(
      baseUrl: 'http://${server.address.host}:${server.port}',
      authTokenProvider: () => 'token-123',
    );

    await client.get('/products');

    expect(authorizationHeader, 'Bearer token-123');
  });

  test('omits bearer token when token provider returns null', () async {
    late String? authorizationHeader;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));

    server.listen((request) async {
      authorizationHeader = request.headers.value(HttpHeaders.authorizationHeader);
      request.response
        ..statusCode = 200
        ..write(jsonEncode(<String, dynamic>{'success': true, 'data': <String, dynamic>{}}));
      await request.response.close();
    });

    final client = ApiClient(
      baseUrl: 'http://${server.address.host}:${server.port}',
      authTokenProvider: () => null,
    );

    await client.get('/products');

    expect(authorizationHeader, isNull);
  });
}
```

- [ ] **Step 2: Run the API client test to verify it fails**

Run:

```powershell
flutter test test/core/network/api_client_test.dart -r expanded
```

Expected:

```text
FAIL ... ApiClient does not accept authTokenProvider yet
```

- [ ] **Step 3: Write the minimal bearer-token and module wiring implementation**

```dart
typedef AuthTokenProvider = String? Function();
```

```dart
import 'package:cafe/core/network/auth_token_provider.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    this.authTokenProvider,
    HttpClient? client,
  }) : _client = client ?? HttpClient();

  final String baseUrl;
  final AuthTokenProvider? authTokenProvider;
  final HttpClient _client;

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters == null
          ? null
          : queryParameters.map((key, value) => MapEntry(key, value.toString())),
    );

    final request = await _client.openUrl(method, uri);
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');

    final bearerToken = authTokenProvider?.call();
    if (bearerToken != null && bearerToken.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
    }

    headers?.forEach(request.headers.set);
    if (body != null) {
      request.write(jsonEncode(body));
    }

    // Keep the existing response decoding and AppException mapping.
  }
}
```

```dart
class ProductModule {
  ProductModule({
    required AppConfig config,
    required AuthTokenProvider authTokenProvider,
  }) {
    final apiClient = ApiClient(
      baseUrl: config.productBaseUrl,
      authTokenProvider: authTokenProvider,
    );
    final remote = ProductRemoteDataSourceImpl(apiClient);
    final repository = ProductRepositoryImpl(remote);

    getProductsUseCase = GetProductsUseCase(repository);
    getProductDetailUseCase = GetProductDetailUseCase(repository);
    createProductUseCase = CreateProductUseCase(repository);
    updateProductUseCase = UpdateProductUseCase(repository);
    updateProductStatusUseCase = UpdateProductStatusUseCase(repository);
    deleteProductUseCase = DeleteProductUseCase(repository);
    restoreProductUseCase = RestoreProductUseCase(repository);
  }

  late final GetProductsUseCase getProductsUseCase;
  late final GetProductDetailUseCase getProductDetailUseCase;
  late final CreateProductUseCase createProductUseCase;
  late final UpdateProductUseCase updateProductUseCase;
  late final UpdateProductStatusUseCase updateProductStatusUseCase;
  late final DeleteProductUseCase deleteProductUseCase;
  late final RestoreProductUseCase restoreProductUseCase;

  ProductManagementController createProductManagementController() {
    return ProductManagementController(
      getProductsUseCase: getProductsUseCase,
      createProductUseCase: createProductUseCase,
      updateProductUseCase: updateProductUseCase,
      updateProductStatusUseCase: updateProductStatusUseCase,
      deleteProductUseCase: deleteProductUseCase,
      restoreProductUseCase: restoreProductUseCase,
    );
  }
}
```

```dart
class CartModule {
  CartModule({
    required AppConfig config,
    required AuthTokenProvider authTokenProvider,
  }) {
    final apiClient = ApiClient(
      baseUrl: config.productBaseUrl,
      authTokenProvider: authTokenProvider,
    );
    final remote = CartRemoteDataSourceImpl(apiClient);
    final repository = CartRepositoryImpl(remote);

    cartRepository = repository;
    addCartItemUseCase = AddCartItemUseCase(repository);
    getMyCartUseCase = GetMyCartUseCase(repository);
    updateCartItemQuantityUseCase = UpdateCartItemQuantityUseCase(repository);
    removeCartItemUseCase = RemoveCartItemUseCase(repository);
    clearMyCartUseCase = ClearMyCartUseCase(repository);
  }
}
```

```dart
class OrderModule {
  OrderModule({
    required AppConfig config,
    required AuthTokenProvider authTokenProvider,
  }) {
    final apiClient = ApiClient(
      baseUrl: config.orderBaseUrl,
      authTokenProvider: authTokenProvider,
    );
    final remote = OrderRemoteDataSourceImpl(apiClient);
    final repository = OrderRepositoryImpl(remote);

    orderRepository = repository;
    checkoutOrderUseCase = CheckoutOrderUseCase(repository);
    getOrdersUseCase = GetOrdersUseCase(repository);
    getOrderDetailUseCase = GetOrderDetailUseCase(repository);
    cancelOrderUseCase = CancelOrderUseCase(repository);
    updateOrderStatusUseCase = UpdateOrderStatusUseCase(repository);
  }
}
```

```dart
class PaymentModule {
  PaymentModule({
    required AppConfig config,
    required AuthTokenProvider authTokenProvider,
  }) {
    final apiClient = ApiClient(
      baseUrl: config.paymentBaseUrl,
      authTokenProvider: authTokenProvider,
    );
    final remote = PaymentRemoteDataSourceImpl(apiClient);
    final repository = PaymentRepositoryImpl(remote);

    paymentRepository = repository;
    initiatePaymentUseCase = InitiatePaymentUseCase(repository);
    getPaymentByOrderUseCase = GetPaymentByOrderUseCase(repository);
  }
}
```

```dart
class AdminModule {
  AdminModule({
    required AppConfig config,
    required AuthTokenProvider authTokenProvider,
  }) {
    final apiClient = ApiClient(
      baseUrl: config.adminBaseUrl,
      authTokenProvider: authTokenProvider,
    );
    final remote = AdminRemoteDataSourceImpl(apiClient);
    final repository = AdminRepositoryImpl(remote);

    getCustomersUseCase = GetCustomersUseCase(repository);
    getCustomerDetailUseCase = GetCustomerDetailUseCase(repository);
    getReportSummaryUseCase = GetReportSummaryUseCase(repository);
    getOrdersReportUseCase = GetOrdersReportUseCase(repository);
    getProductsReportUseCase = GetProductsReportUseCase(repository);
    exportReportUseCase = ExportReportUseCase(repository);
  }
}
```

```dart
final productModule = ProductModule(
  config: config,
  authTokenProvider: () => sessionController.accessToken,
);
final cartModule = CartModule(
  config: config,
  authTokenProvider: () => sessionController.accessToken,
);
final orderModule = OrderModule(
  config: config,
  authTokenProvider: () => sessionController.accessToken,
);
final paymentModule = PaymentModule(
  config: config,
  authTokenProvider: () => sessionController.accessToken,
);
final adminModule = AdminModule(
  config: config,
  authTokenProvider: () => sessionController.accessToken,
);
```

```dart
return AdminDashboardPage(
  role: role,
  orderModule: orderModule,
  productModule: productModule,
  adminModule: adminModule,
  sessionController: sessionController,
);
```

```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => ProductManagementPage(
      role: widget.role,
      controller: widget.productModule.createProductManagementController(),
    ),
  ),
);
```

- [ ] **Step 4: Run the API client test to verify it passes**

Run:

```powershell
flutter test test/core/network/api_client_test.dart -r expanded
```

Expected:

```text
00:00 +2: All tests passed!
```

- [ ] **Step 5: Commit**

```powershell
git add lib/core/network/auth_token_provider.dart lib/core/network/api_client.dart lib/app/di/product_module.dart lib/app/di/cart_module.dart lib/app/di/order_module.dart lib/app/di/payment_module.dart lib/app/di/admin_module.dart lib/app/router/app_shell_page.dart lib/features/admin/presentation/pages/admin_dashboard_page.dart lib/main.dart test/core/network/api_client_test.dart
git commit -m "feat: share auth token across API modules"
```

## Task 5: Build Remote Product Public Controllers

**Files:**
- Create: `lib/features/product/presentation/cubit/product_home_controller.dart`
- Modify: `lib/features/product/presentation/cubit/product_catalog_controller.dart`
- Test: `test/features/product/presentation/cubit/product_home_controller_test.dart`
- Test: `test/features/product/presentation/cubit/product_catalog_controller_test.dart`

- [ ] **Step 1: Write failing controller tests**

```dart
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_catalog_controller.dart';
import 'package:cafe/features/product/presentation/cubit/product_home_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this.page);

  final ProductListPage page;
  int getProductsCallCount = 0;

  @override
  Future<ProductListPage> getProducts(ProductQuery query) async {
    getProductsCallCount += 1;
    return page;
  }

  @override
  Future<Product> getProductDetail(String id) => throw UnimplementedError();
  @override
  Future<Product> createProduct(UpsertProductInput input) => throw UnimplementedError();
  @override
  Future<Product> updateProduct(String id, UpsertProductInput input) => throw UnimplementedError();
  @override
  Future<Product> updateProductStatus(String id, String status) => throw UnimplementedError();
  @override
  Future<void> deleteProduct(String id) => throw UnimplementedError();
  @override
  Future<Product> restoreProduct(String id) => throw UnimplementedError();
}

Product _product({
  required String id,
  required ProductStatus status,
  int totalSold = 0,
}) {
  final now = DateTime(2026, 1, 1);
  return Product(
    id: id,
    name: 'Product $id',
    description: 'Desc',
    price: 25000,
    category: ProductCategory.coffee,
    status: status,
    imageUrl: 'https://example.com/$id.png',
    rating: 4.5,
    totalSold: totalSold,
    attributes: const ProductAttributes(
      temperature: <String>['hot'],
      sugarLevels: <String>['normal'],
      sizes: <String>['small'],
    ),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('ProductCatalogController hides unavailable products in public flow', () async {
    final repository = _FakeProductRepository(
      ProductListPage(
        data: <Product>[
          _product(id: 'available', status: ProductStatus.available),
          _product(id: 'out', status: ProductStatus.outOfStock),
          _product(id: 'hidden', status: ProductStatus.unavailable),
        ],
        nextCursor: null,
        prevCursor: null,
        limit: 10,
        hasNext: false,
        hasPrev: false,
      ),
    );
    final controller = ProductCatalogController(GetProductsUseCase(repository));

    await controller.fetchInitial();

    expect(controller.products.map((product) => product.id), <String>['available', 'out']);
  });

  test('ProductHomeController loads featured products and hides unavailable ones', () async {
    final repository = _FakeProductRepository(
      ProductListPage(
        data: <Product>[
          _product(id: 'best-1', status: ProductStatus.available, totalSold: 40),
          _product(id: 'best-2', status: ProductStatus.outOfStock, totalSold: 30),
          _product(id: 'hidden', status: ProductStatus.unavailable, totalSold: 50),
        ],
        nextCursor: null,
        prevCursor: null,
        limit: 8,
        hasNext: false,
        hasPrev: false,
      ),
    );
    final controller = ProductHomeController(GetProductsUseCase(repository));

    await controller.loadFeatured();

    expect(controller.products.map((product) => product.id), <String>['best-1', 'best-2']);
    expect(repository.getProductsCallCount, 1);
  });
}
```

- [ ] **Step 2: Run the controller tests to verify they fail**

Run:

```powershell
flutter test test/features/product/presentation/cubit/product_catalog_controller_test.dart -r expanded
flutter test test/features/product/presentation/cubit/product_home_controller_test.dart -r expanded
```

Expected:

```text
FAIL ... ProductHomeController does not exist yet
FAIL ... ProductCatalogController still exposes unavailable products or seed/mock path
```

- [ ] **Step 3: Write the minimal public-product controller implementation**

```dart
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:flutter/foundation.dart';

class ProductHomeController extends ChangeNotifier {
  ProductHomeController(this._getProductsUseCase);

  final GetProductsUseCase _getProductsUseCase;

  final List<Product> _products = <Product>[];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadFeatured() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _getProductsUseCase(
        const ProductQuery(
          limit: 8,
          sortBy: ProductSortBy.totalSold,
          sortDirection: SortDirection.desc,
        ),
      );
      _products
        ..clear()
        ..addAll(
          page.data.where(
            (product) => product.status != ProductStatus.unavailable,
          ),
        );
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

```dart
class ProductCatalogController extends ChangeNotifier {
  ProductCatalogController(this._getProductsUseCase);

  final GetProductsUseCase _getProductsUseCase;

  List<Product> _publicVisible(List<Product> source) {
    return source
        .where((product) => product.status != ProductStatus.unavailable)
        .toList(growable: false);
  }

  Future<void> fetchInitial() async {
    _products.clear();
    _nextCursor = null;
    _hasNext = false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _getProductsUseCase(_query.copyWith(cursor: null));
      _products
        ..clear()
        ..addAll(_publicVisible(page.data));
      _nextCursor = page.nextCursor;
      _hasNext = page.hasNext;
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchNext() async {
    if (_isPaginating || !_hasNext || _nextCursor == null) {
      return;
    }

    _isPaginating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _getProductsUseCase(_query.copyWith(cursor: _nextCursor));
      _products.addAll(_publicVisible(page.data));
      _nextCursor = page.nextCursor;
      _hasNext = page.hasNext;
    } catch (error) {
      _errorMessage = '$error';
    } finally {
      _isPaginating = false;
      notifyListeners();
    }
  }
}
```

- [ ] **Step 4: Run the controller tests to verify they pass**

Run:

```powershell
flutter test test/features/product/presentation/cubit/product_catalog_controller_test.dart -r expanded
flutter test test/features/product/presentation/cubit/product_home_controller_test.dart -r expanded
```

Expected:

```text
00:00 +1: All tests passed!
00:00 +1: All tests passed!
```

- [ ] **Step 5: Commit**

```powershell
git add lib/features/product/presentation/cubit/product_home_controller.dart lib/features/product/presentation/cubit/product_catalog_controller.dart test/features/product/presentation/cubit/product_catalog_controller_test.dart test/features/product/presentation/cubit/product_home_controller_test.dart
git commit -m "feat: add remote product public controllers"
```

## Task 6: Rewire Customer Product Pages to Remote Data

**Files:**
- Modify: `lib/features/product/presentation/pages/product_home_page.dart`
- Modify: `lib/features/product/presentation/pages/product_catalog_page.dart`
- Modify: `lib/features/product/presentation/pages/product_detail_page.dart`
- Test: `test/features/product/presentation/pages/product_home_page_test.dart`
- Modify/Test: `test/features/product/presentation/pages/product_detail_page_test.dart`

- [ ] **Step 1: Write failing page tests**

```dart
import 'package:cafe/app/config/app_config.dart';
import 'package:cafe/app/di/cart_module.dart';
import 'package:cafe/app/di/order_module.dart';
import 'package:cafe/app/di/payment_module.dart';
import 'package:cafe/features/auth/domain/entities/auth_session.dart';
import 'package:cafe/features/auth/domain/repositories/auth_repository.dart';
import 'package:cafe/features/auth/domain/usecases/login_usecase.dart';
import 'package:cafe/features/auth/domain/usecases/logout_usecase.dart';
import 'package:cafe/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:cafe/features/cart/domain/entities/cart.dart';
import 'package:cafe/features/cart/domain/entities/cart_item.dart';
import 'package:cafe/features/cart/domain/repositories/cart_repository.dart';
import 'package:cafe/features/cart/domain/usecases/add_cart_item_usecase.dart';
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';
import 'package:cafe/features/product/domain/usecases/get_product_detail_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/presentation/pages/product_detail_page.dart';
import 'package:cafe/features/product/presentation/pages/product_home_page.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:cafe/shared/services/session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this._page);

  final ProductListPage _page;

  @override
  Future<ProductListPage> getProducts(ProductQuery query) async => _page;

  @override
  Future<Product> getProductDetail(String id) async {
    return _page.data.first;
  }

  @override
  Future<Product> createProduct(UpsertProductInput input) => throw UnimplementedError();
  @override
  Future<Product> updateProduct(String id, UpsertProductInput input) => throw UnimplementedError();
  @override
  Future<Product> updateProductStatus(String id, String status) => throw UnimplementedError();
  @override
  Future<void> deleteProduct(String id) => throw UnimplementedError();
  @override
  Future<Product> restoreProduct(String id) => throw UnimplementedError();
}

class _ThrowingAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({required String email, required String password}) => throw UnimplementedError();
  @override
  Future<void> logout() async {}
  @override
  Future<AuthSession?> restoreSession() async => null;
}

class _ThrowingProductRepository implements ProductRepository {
  @override
  Future<Product> getProductDetail(String id) async {
    throw Exception('produk tidak ditemukan');
  }

  @override
  Future<ProductListPage> getProducts(ProductQuery query) => throw UnimplementedError();
  @override
  Future<Product> createProduct(UpsertProductInput input) => throw UnimplementedError();
  @override
  Future<Product> updateProduct(String id, UpsertProductInput input) => throw UnimplementedError();
  @override
  Future<Product> updateProductStatus(String id, String status) => throw UnimplementedError();
  @override
  Future<void> deleteProduct(String id) => throw UnimplementedError();
  @override
  Future<Product> restoreProduct(String id) => throw UnimplementedError();
}

class _FakeCartRepository implements CartRepository {
  const _FakeCartRepository();

  static const Cart _emptyCart = Cart(
    cartId: null,
    userId: 'test-user',
    items: <CartItem>[],
    grandTotal: 0,
    updatedAt: null,
  );

  @override
  Future<Cart> addItem({required String productId, required int quantity}) async => _emptyCart;
  @override
  Future<void> clearMyCart() async {}
  @override
  Future<Cart> getMyCart() async => _emptyCart;
  @override
  Future<void> removeItem(String itemId) async {}
  @override
  Future<Cart> updateItemQuantity({required String itemId, required int quantity}) async => _emptyCart;
}

Product _product() {
  final now = DateTime(2026, 1, 1);
  return Product(
    id: 'product-1',
    name: 'Americano',
    description: 'Desc',
    price: 25000,
    category: ProductCategory.coffee,
    status: ProductStatus.available,
    imageUrl: 'https://invalid.example/image.png',
    rating: 4.5,
    totalSold: 10,
    attributes: const ProductAttributes(
      temperature: <String>['hot'],
      sugarLevels: <String>['normal'],
      sizes: <String>['small'],
    ),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('ProductHomePage renders remote featured products', (tester) async {
    final repository = _FakeProductRepository(
      ProductListPage(
        data: <Product>[_product()],
        nextCursor: null,
        prevCursor: null,
        limit: 8,
        hasNext: false,
        hasPrev: false,
      ),
    );
    final sessionController = SessionController(
      loginUseCase: LoginUseCase(_ThrowingAuthRepository()),
      logoutUseCase: LogoutUseCase(_ThrowingAuthRepository()),
      restoreSessionUseCase: RestoreSessionUseCase(_ThrowingAuthRepository()),
    );
    const config = AppConfig(
      backendOrigin: 'http://10.0.2.2:8080',
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon-key',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProductHomePage(
          sessionController: sessionController,
          cartModule: CartModule(config: config, authTokenProvider: () => null),
          orderModule: OrderModule(config: config, authTokenProvider: () => null),
          paymentModule: PaymentModule(config: config, authTokenProvider: () => null),
          getProductsUseCase: GetProductsUseCase(repository),
          getProductDetailUseCase: GetProductDetailUseCase(repository),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Americano'), findsOneWidget);
  });

  testWidgets('ProductDetailPage shows retry action on error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailPage(
          productId: 'missing-id',
          getProductDetailUseCase: GetProductDetailUseCase(_ThrowingProductRepository()),
          addCartItemUseCase: const AddCartItemUseCase(_FakeCartRepository()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run the page tests to verify they fail**

Run:

```powershell
flutter test test/features/product/presentation/pages/product_home_page_test.dart -r expanded
flutter test test/features/product/presentation/pages/product_detail_page_test.dart -r expanded
```

Expected:

```text
FAIL ... ProductHomePage still depends on ProductMockStore
FAIL ... ProductDetailPage has no retry action in error state
```

- [ ] **Step 3: Write the minimal page implementation**

```dart
class _ProductHomePageState extends State<ProductHomePage> {
  late final ProductHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProductHomeController(widget.getProductsUseCase);
    _controller.loadFeatured();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildFeaturedProducts() {
    if (_controller.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_controller.errorMessage != null) {
      return Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _controller.errorMessage!,
                textAlign: TextAlign.center,
              ),
            ),
            TextButton(
              onPressed: _controller.loadFeatured,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    final featuredProducts = _controller.products;
    if (featuredProducts.isEmpty) {
      return const Center(child: Text('Belum ada produk'));
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: featuredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final product = featuredProducts[index];
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ProductDetailPage(
                  productId: product.id,
                  initialProduct: product,
                  getProductDetailUseCase: widget.getProductDetailUseCase,
                  addCartItemUseCase: widget.cartModule.addCartItemUseCase,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.network(
                    product.imageUrl,
                    width: double.infinity,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 140,
                      color: const Color(0xFFDCDCDC),
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.category.label,
                        style: const TextStyle(
                          color: Color(0xFF6E5C52),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

```dart
class ProductCatalogPage extends StatefulWidget {
  const ProductCatalogPage({
    super.key,
    required this.getProductsUseCase,
    required this.getProductDetailUseCase,
    required this.addCartItemUseCase,
    this.initialCategory,
  });

  final GetProductsUseCase getProductsUseCase;
  final GetProductDetailUseCase getProductDetailUseCase;
  final AddCartItemUseCase addCartItemUseCase;
  final ProductCategory? initialCategory;
}
```

```dart
void _openCatalog(BuildContext context, ProductCategory? category) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProductCatalogPage(
        getProductsUseCase: widget.getProductsUseCase,
        getProductDetailUseCase: widget.getProductDetailUseCase,
        addCartItemUseCase: widget.cartModule.addCartItemUseCase,
        initialCategory: category,
      ),
    ),
  );
}
```

```dart
if (_controller.errorMessage != null || product == null) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _controller.errorMessage ?? 'Produk tidak ditemukan',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _controller.load(widget.productId),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 4: Run the page tests to verify they pass**

Run:

```powershell
flutter test test/features/product/presentation/pages/product_home_page_test.dart -r expanded
flutter test test/features/product/presentation/pages/product_detail_page_test.dart -r expanded
```

Expected:

```text
00:00 +1: All tests passed!
00:00 +3: All tests passed!
```

- [ ] **Step 5: Commit**

```powershell
git add lib/features/product/presentation/pages/product_home_page.dart lib/features/product/presentation/pages/product_catalog_page.dart lib/features/product/presentation/pages/product_detail_page.dart test/features/product/presentation/pages/product_home_page_test.dart test/features/product/presentation/pages/product_detail_page_test.dart
git commit -m "feat: connect customer product pages to backend"
```

## Task 7: Replace Product Management Mock Flow

**Files:**
- Modify: `lib/features/product/presentation/pages/product_management_page.dart`
- Modify: `lib/features/admin/presentation/pages/admin_dashboard_page.dart`
- Modify: `lib/app/di/product_module.dart`
- Test: `test/features/product/presentation/cubit/product_management_controller_test.dart`
- Test: `test/features/product/presentation/pages/product_management_page_test.dart`

- [ ] **Step 1: Write failing product-management tests**

```dart
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_attributes.dart';
import 'package:cafe/features/product/domain/entities/product_enums.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';
import 'package:cafe/features/product/domain/usecases/create_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/domain/usecases/restore_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_status_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_management_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingProductRepository implements ProductRepository {
  int getProductsCallCount = 0;
  int createCallCount = 0;

  @override
  Future<ProductListPage> getProducts(ProductQuery query) async {
    getProductsCallCount += 1;
    return const ProductListPage(
      data: <Product>[],
      nextCursor: null,
      prevCursor: null,
      limit: 50,
      hasNext: false,
      hasPrev: false,
    );
  }

  @override
  Future<Product> createProduct(UpsertProductInput input) async {
    createCallCount += 1;
    final now = DateTime(2026, 1, 1);
    return Product(
      id: 'created-1',
      name: input.name ?? 'Created',
      description: input.description ?? '',
      price: input.price ?? 0,
      category: input.category ?? ProductCategory.coffee,
      status: input.status ?? ProductStatus.available,
      imageUrl: input.imageUrl ?? '',
      rating: 0,
      totalSold: 0,
      attributes: input.attributes ?? const ProductAttributes(),
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Product> getProductDetail(String id) => throw UnimplementedError();
  @override
  Future<Product> updateProduct(String id, UpsertProductInput input) => throw UnimplementedError();
  @override
  Future<Product> updateProductStatus(String id, String status) => throw UnimplementedError();
  @override
  Future<void> deleteProduct(String id) async {}
  @override
  Future<Product> restoreProduct(String id) => throw UnimplementedError();
}

void main() {
  test('createProduct reloads list after successful mutation', () async {
    final repository = _RecordingProductRepository();
    final controller = ProductManagementController(
      getProductsUseCase: GetProductsUseCase(repository),
      createProductUseCase: CreateProductUseCase(repository),
      updateProductUseCase: UpdateProductUseCase(repository),
      updateProductStatusUseCase: UpdateProductStatusUseCase(repository),
      deleteProductUseCase: DeleteProductUseCase(repository),
      restoreProductUseCase: RestoreProductUseCase(repository),
    );

    await controller.loadProducts();
    await controller.createProduct(
      const UpsertProductInput(
        name: 'Americano',
        price: 25000,
        category: ProductCategory.coffee,
        status: ProductStatus.available,
        imageUrl: 'https://example.com/americano.png',
        attributes: ProductAttributes(
          temperature: <String>['hot'],
          sugarLevels: <String>['normal'],
          sizes: <String>['small'],
        ),
      ),
    );

    expect(repository.createCallCount, 1);
    expect(repository.getProductsCallCount, 2);
  });
}
```

```dart
import 'package:cafe/features/product/domain/entities/product.dart';
import 'package:cafe/features/product/domain/entities/product_list_page.dart';
import 'package:cafe/features/product/domain/entities/product_query.dart';
import 'package:cafe/features/product/domain/entities/upsert_product_input.dart';
import 'package:cafe/features/product/domain/repositories/product_repository.dart';
import 'package:cafe/features/product/domain/usecases/create_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/delete_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/get_products_usecase.dart';
import 'package:cafe/features/product/domain/usecases/restore_product_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_status_usecase.dart';
import 'package:cafe/features/product/domain/usecases/update_product_usecase.dart';
import 'package:cafe/features/product/presentation/cubit/product_management_controller.dart';
import 'package:cafe/features/product/presentation/pages/product_management_page.dart';
import 'package:cafe/shared/models/app_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PageRepository implements ProductRepository {
  @override
  Future<ProductListPage> getProducts(ProductQuery query) async {
    return const ProductListPage(
      data: <Product>[],
      nextCursor: null,
      prevCursor: null,
      limit: 50,
      hasNext: false,
      hasPrev: false,
    );
  }

  @override
  Future<Product> createProduct(UpsertProductInput input) => throw UnimplementedError();
  @override
  Future<Product> getProductDetail(String id) => throw UnimplementedError();
  @override
  Future<Product> restoreProduct(String id) => throw UnimplementedError();
  @override
  Future<Product> updateProduct(String id, UpsertProductInput input) => throw UnimplementedError();
  @override
  Future<Product> updateProductStatus(String id, String status) => throw UnimplementedError();
  @override
  Future<void> deleteProduct(String id) async {}
}

ProductManagementController _buildController() {
  final repository = _PageRepository();
  return ProductManagementController(
    getProductsUseCase: GetProductsUseCase(repository),
    createProductUseCase: CreateProductUseCase(repository),
    updateProductUseCase: UpdateProductUseCase(repository),
    updateProductStatusUseCase: UpdateProductStatusUseCase(repository),
    deleteProductUseCase: DeleteProductUseCase(repository),
    restoreProductUseCase: RestoreProductUseCase(repository),
  );
}

void main() {
  testWidgets('pegawai sees disabled add button in product management', (tester) async {
    final controller = _buildController();

    await tester.pumpWidget(
      MaterialApp(
        home: ProductManagementPage(
          role: UserRole.pegawai,
          controller: controller,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Tambah'),
    );
    expect(button.onPressed, isNull);
  });
}
```

- [ ] **Step 2: Run the management tests to verify they fail**

Run:

```powershell
flutter test test/features/product/presentation/cubit/product_management_controller_test.dart -r expanded
flutter test test/features/product/presentation/pages/product_management_page_test.dart -r expanded
```

Expected:

```text
FAIL ... ProductManagementPage constructor does not accept a real controller yet
FAIL ... page still depends on _ProductManagementMockController
```

- [ ] **Step 3: Write the minimal product-management implementation**

```dart
class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({
    super.key,
    required this.role,
    required this.controller,
  });

  final UserRole role;
  final ProductManagementController controller;
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  late final ProductManagementController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _searchController = TextEditingController(text: _controller.search);
    _controller.loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCreateDialog(BuildContext context) async {
    final result = await showDialog<UpsertProductInput>(
      context: context,
      builder: (_) => const _ProductFormDialog(),
    );
    if (result == null) return;

    await _controller.createProduct(result);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk berhasil dibuat')),
    );
  }
}
```

```dart
void _openProductManagement() {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProductManagementPage(
        role: widget.role,
        controller: widget.productModule.createProductManagementController(),
      ),
    ),
  );
}
```

```dart
FilterChip(
  label: const Text('Include soft-deleted'),
  selected: _controller.includeDeleted,
  onSelected: isAdmin ? _controller.toggleIncludeDeleted : null,
  selectedColor: const Color(0x1AD88A16),
),
```

```dart
Future<void> _pickStatus(
  BuildContext context,
  Product product, {
  required bool isAdmin,
}) async {
  final statuses = <ProductStatus>[
    ProductStatus.available,
    ProductStatus.outOfStock,
    if (isAdmin) ProductStatus.unavailable,
  ];

  final selected = await showDialog<ProductStatus>(
    context: context,
    builder: (ctx) {
      return SimpleDialog(
        title: const Text('Pilih status'),
        children: statuses
            .map(
              (status) => SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, status),
                child: Text(status.value),
              ),
            )
            .toList(),
      );
    },
  );

  if (selected == null) return;
  await _controller.updateStatus(product.id, selected.value);
}
```

- [ ] **Step 4: Run the management tests to verify they pass**

Run:

```powershell
flutter test test/features/product/presentation/cubit/product_management_controller_test.dart -r expanded
flutter test test/features/product/presentation/pages/product_management_page_test.dart -r expanded
```

Expected:

```text
00:00 +1: All tests passed!
00:00 +1: All tests passed!
```

- [ ] **Step 5: Commit**

```powershell
git add lib/features/product/presentation/pages/product_management_page.dart lib/features/admin/presentation/pages/admin_dashboard_page.dart lib/app/di/product_module.dart test/features/product/presentation/cubit/product_management_controller_test.dart test/features/product/presentation/pages/product_management_page_test.dart
git commit -m "feat: connect product management to backend"
```

## Task 8: Full Verification and Manual Emulator Check

**Files:**
- Modify: `lib/main.dart` (only if any final compile fix remains after the previous tasks)
- Test: existing `test/features/product/data/models/product_model_test.dart`
- Test: existing `test/features/product/presentation/pages/product_detail_page_test.dart`
- Test: entire `test/` suite

- [ ] **Step 1: Run the focused auth and product test suite**

Run:

```powershell
flutter test test/app/config/app_config_test.dart -r expanded
flutter test test/core/network/api_client_test.dart -r expanded
flutter test test/features/auth -r expanded
flutter test test/features/product -r expanded
flutter test test/shared/services/session_controller_test.dart -r expanded
```

Expected:

```text
All targeted auth/product tests pass with 0 failures.
```

- [ ] **Step 2: Run the full automated verification**

Run:

```powershell
flutter analyze
flutter test
```

Expected:

```text
Analyzing cafe... no issues found!
All tests passed.
```

- [ ] **Step 3: Run the app on Android emulator with real runtime config and manually verify login + product flows**

Run:

```powershell
flutter run `
  --dart-define=BACKEND_ORIGIN=http://10.0.2.2:8080 `
  --dart-define=SUPABASE_URL=https://kangzprbrstwuuejpmso.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imthbmd6cHJicnN0d3V1ZWpwbXNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU1MjY3ODgsImV4cCI6MjA5MTEwMjc4OH0.Ioo0A7Kw3HMQQd7k5W5r6xUlBpvi4o_T3NdCtSag3y4
```

Expected manual checks:

```text
1. Login succeeds with a real Supabase account.
2. Customer home shows remote featured products.
3. Catalog search/filter works and hides unavailable products.
4. Detail page loads from backend and retry works on error.
5. Admin or pegawai product management loads real products.
6. Admin can create/update/delete/restore, pegawai can update status only.
```

- [ ] **Step 4: Commit the finished integration**

```powershell
git add lib test pubspec.yaml pubspec.lock
git commit -m "feat: integrate Supabase auth and product backend"
```

## Coverage Check

- Auth login via Supabase: Task 2, Task 3
- Backend profile fetch and role mapping: Task 2, Task 3
- Shared bearer-token plumbing: Task 4
- Product home/catalog/detail: Task 5, Task 6
- Product management CRUD/status/delete/restore: Task 7
- Loading/error/empty states: Task 3, Task 5, Task 6, Task 7
- Verification on emulator: Task 8




