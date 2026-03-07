import 'package:agribridge/core/error/failures.dart';
import 'package:agribridge/features/auth/presentation/state/auth_state.dart';
import 'package:agribridge/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:agribridge/features/dashboard/domain/usecases/get_profile_usecase.dart';
import 'package:agribridge/features/dashboard/domain/usecases/order_usecase.dart';
import 'package:agribridge/features/dashboard/domain/usecases/save_profile_image_usecase.dart';
import 'package:agribridge/features/dashboard/presentation/view_model/order_view_model.dart';
import 'package:agribridge/features/dashboard/presentation/view_model/profile_view_model.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ViewModel unit tests', () {
    late SharedPreferences prefs;
    late TestUserSessionService userSessionService;
    late TestAuthRepository authRepository;
    late AuthViewModel authViewModel;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      userSessionService = TestUserSessionService(
        prefs: prefs,
        currentUserId: 'user-1',
      );
      authRepository = TestAuthRepository();
      authViewModel = buildTestAuthViewModel(
        repository: authRepository,
        userSessionService: userSessionService,
      );
    });

    test('1. AuthViewModel login success sets authenticated state', () async {
      final expectedUser = sampleAuthEntity(
        authId: 'auth-123',
        email: 'user@example.com',
      );
      authRepository.onLogin = (email, password) async => Right(expectedUser);

      await authViewModel.login('user@example.com', 'pass1234');

      expect(authViewModel.state.status, AuthStatus.authenticated);
      expect(authViewModel.state.authEntity, expectedUser);
      expect(userSessionService.syncBiometricStateAfterLoginCalls, 1);
      expect(userSessionService.saveBiometricCredentialsCalls, 1);
    });

    test('2. AuthViewModel login failure sets error state', () async {
      authRepository.onLogin = (email, password) async {
        return const Left(ApiFailure(message: 'Invalid email or password'));
      };

      await authViewModel.login('user@example.com', 'wrong-pass');

      expect(authViewModel.state.status, AuthStatus.error);
      expect(authViewModel.state.errorMessage, 'Invalid email or password');
    });

    test('3. AuthViewModel register success sets registered status', () async {
      authRepository.onRegister = (entity) async => const Right(true);

      await authViewModel.register(
        fullName: 'Test User',
        email: 'test@example.com',
        username: 'test_user',
        password: 'secret123',
      );

      expect(authViewModel.state.status, AuthStatus.registered);
      expect(authViewModel.state.errorMessage, isNull);
    });

    test('4. AuthViewModel register false response sets error', () async {
      authRepository.onRegister = (entity) async => const Right(false);

      await authViewModel.register(
        fullName: 'Test User',
        email: 'test@example.com',
        username: 'test_user',
        password: 'secret123',
      );

      expect(authViewModel.state.status, AuthStatus.error);
      expect(authViewModel.state.errorMessage, 'Registration failed');
    });

    test('5. AuthViewModel resetError clears error and resets status', () async {
      authRepository.onRegister = (entity) async {
        return const Left(ApiFailure(message: 'Email already exists'));
      };
      await authViewModel.register(
        fullName: 'Test User',
        email: 'test@example.com',
        username: 'test_user',
        password: 'secret123',
      );

      authViewModel.resetError();

      expect(authViewModel.state.status, AuthStatus.initial);
      expect(authViewModel.state.errorMessage, isNull);
    });

    test(
      '6. AuthViewModel changePassword sanitizes Exception prefix from failures',
      () async {
        authRepository.onChangePassword = (userId, currentPassword, newPassword) {
          return Future.value(
            const Left(
              ApiFailure(message: 'Exception: Current password is incorrect'),
            ),
          );
        };

        final result = await authViewModel.changePassword(
          userId: 'user-1',
          currentPassword: 'old12345',
          newPassword: 'new12345',
        );

        expect(result, 'Current password is incorrect');
      },
    );

    test('7. AuthViewModel deleteAccount sanitizes thrown exception', () async {
      authRepository.onDeleteAccount = (userId, currentPassword) {
        throw Exception('Delete failed');
      };

      final result = await authViewModel.deleteAccount(
        userId: 'user-1',
        currentPassword: 'secret123',
      );

      expect(result, 'Delete failed');
    });

    test('8. OrderViewModel loadOrders success emits data state', () async {
      final repository = TestOrderRepository(
        onGetMyOrders: () async => [sampleOrderEntity(orderId: 'order-100')],
      );
      final usecase = GetMyOrdersUseCase(repository);
      final viewModel = OrderViewModel(getMyOrdersUseCase: usecase);

      await viewModel.loadOrders();

      expect(viewModel.state.hasValue, isTrue);
      expect(viewModel.state.value, isNotNull);
      expect(viewModel.state.value!.length, 1);
      expect(viewModel.state.value!.first.orderId, 'order-100');
    });

    test('9. OrderViewModel loadOrders failure emits error state', () async {
      final repository = TestOrderRepository(
        onGetMyOrders: () async {
          throw Exception('Network error');
        },
      );
      final usecase = GetMyOrdersUseCase(repository);
      final viewModel = OrderViewModel(getMyOrdersUseCase: usecase);

      await viewModel.loadOrders();

      expect(viewModel.state.hasError, isTrue);
      expect(viewModel.state.error.toString(), contains('Network error'));
    });

    test('10. ProfileViewModel saveProfileImage failure sets error', () async {
      final repository = TestProfileRepository(
        onSaveProfileImage: (imagePath, customerId) async {
          throw Exception('Unable to save profile image');
        },
      );
      final viewModel = ProfileViewModel(
        getProfileUseCase: GetProfileUseCase(repository),
        saveProfileImageUseCase: SaveProfileImageUseCase(repository),
      );

      await viewModel.saveProfileImage('image.png', 'customer-1');

      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.error, contains('Unable to save profile image'));
    });
  });
}
