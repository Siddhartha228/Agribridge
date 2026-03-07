import 'package:agribridge/core/error/failures.dart';
import 'package:agribridge/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/get_current_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/login_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/register_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/reset_forgot_password_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/send_forgot_password_otp_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/verify_forgot_password_otp_usecase.dart';
import 'package:agribridge/features/dashboard/domain/usecases/home_usecase.dart';
import 'package:agribridge/features/dashboard/domain/usecases/order_usecase.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_fakes.dart';

void main() {
  group('Usecase unit tests', () {
    test('1. LoginUsecase delegates to repository login', () async {
      String? receivedEmail;
      String? receivedPassword;

      final expected = sampleAuthEntity(email: 'user@example.com');
      final repository = TestAuthRepository(
        onLogin: (email, password) async {
          receivedEmail = email;
          receivedPassword = password;
          return Right(expected);
        },
      );

      final usecase = LoginUsecase(authRepository: repository);
      const params = LoginUsecaseParams(
        username: 'user@example.com',
        password: 'secret123',
      );

      final result = await usecase(params);

      expect(result, Right(expected));
      expect(receivedEmail, params.username);
      expect(receivedPassword, params.password);
    });

    test('2. RegisterUsecase maps params into AuthEntity', () async {
      final expected = const Right<Failure, bool>(true);
      var capturedEntity = sampleAuthEntity();
      final repository = TestAuthRepository(
        onRegister: (entity) async {
          capturedEntity = entity;
          return expected;
        },
      );

      final usecase = RegisterUsecase(authRepository: repository);
      const params = RegisterUsecaseParams(
        fullName: 'Test User',
        email: 'test@example.com',
        username: 'test_user',
        password: 'pass1234',
      );

      final result = await usecase(params);

      expect(result, expected);
      expect(capturedEntity.fullName, params.fullName);
      expect(capturedEntity.email, params.email);
      expect(capturedEntity.username, params.username);
      expect(capturedEntity.password, params.password);
    });

    test('3. ChangePasswordUsecase delegates with exact arguments', () async {
      String? userId;
      String? currentPassword;
      String? newPassword;

      final repository = TestAuthRepository(
        onChangePassword: (id, current, next) async {
          userId = id;
          currentPassword = current;
          newPassword = next;
          return const Right(true);
        },
      );

      final usecase = ChangePasswordUsecase(authRepository: repository);
      const params = ChangePasswordUsecaseParams(
        userId: 'u1',
        currentPassword: 'old12345',
        newPassword: 'new12345',
      );

      final result = await usecase(params);

      expect(result, const Right(true));
      expect(userId, params.userId);
      expect(currentPassword, params.currentPassword);
      expect(newPassword, params.newPassword);
    });

    test('4. DeleteAccountUsecase delegates with exact arguments', () async {
      String? userId;
      String? currentPassword;

      final repository = TestAuthRepository(
        onDeleteAccount: (id, current) async {
          userId = id;
          currentPassword = current;
          return const Right(true);
        },
      );

      final usecase = DeleteAccountUsecase(authRepository: repository);
      const params = DeleteAccountUsecaseParams(
        userId: 'u2',
        currentPassword: 'secret123',
      );

      final result = await usecase(params);

      expect(result, const Right(true));
      expect(userId, params.userId);
      expect(currentPassword, params.currentPassword);
    });

    test('5. SendForgotPasswordOtpUsecase delegates email', () async {
      String? email;
      final repository = TestAuthRepository(
        onSendForgotPasswordOtp: (value) async {
          email = value;
          return const Right(true);
        },
      );
      final usecase = SendForgotPasswordOtpUsecase(authRepository: repository);
      const params = SendForgotPasswordOtpUsecaseParams(
        email: 'user@example.com',
      );

      final result = await usecase(params);

      expect(result, const Right(true));
      expect(email, params.email);
    });

    test('6. VerifyForgotPasswordOtpUsecase delegates email and otp', () async {
      String? email;
      String? otp;
      final repository = TestAuthRepository(
        onVerifyForgotPasswordOtp: (value, code) async {
          email = value;
          otp = code;
          return const Right(true);
        },
      );
      final usecase = VerifyForgotPasswordOtpUsecase(
        authRepository: repository,
      );
      const params = VerifyForgotPasswordOtpUsecaseParams(
        email: 'user@example.com',
        otp: '123456',
      );

      final result = await usecase(params);

      expect(result, const Right(true));
      expect(email, params.email);
      expect(otp, params.otp);
    });

    test(
      '7. ResetForgotPasswordUsecase delegates all reset password values',
      () async {
        String? email;
        String? otp;
        String? newPassword;
        String? confirmPassword;

        final repository = TestAuthRepository(
          onResetForgotPassword: (value, code, next, confirm) async {
            email = value;
            otp = code;
            newPassword = next;
            confirmPassword = confirm;
            return const Right(true);
          },
        );
        final usecase = ResetForgotPasswordUsecase(authRepository: repository);
        const params = ResetForgotPasswordUsecaseParams(
          email: 'user@example.com',
          otp: '654321',
          newPassword: 'newPass123',
          confirmPassword: 'newPass123',
        );

        final result = await usecase(params);

        expect(result, const Right(true));
        expect(email, params.email);
        expect(otp, params.otp);
        expect(newPassword, params.newPassword);
        expect(confirmPassword, params.confirmPassword);
      },
    );

    test('8. GetCurrentUserUsecase delegates to repository getCurrentUser', () async {
      final expected = sampleAuthEntity(authId: 'auth-9');
      final repository = TestAuthRepository(
        onGetCurrentUser: () async => Right(expected),
      );
      final usecase = GetCurrentUserUsecase(authRepository: repository);

      final result = await usecase();

      expect(result, Right(expected));
    });

    test('9. GetHomeProductsUseCase returns repository products', () async {
      final expected = [sampleHomeEntity(name: 'Onion')];
      final repository = TestHomeRepository(onGetProducts: () async => expected);
      final usecase = GetHomeProductsUseCase(repository);

      final result = await usecase();

      expect(result, expected);
    });

    test('10. GetMyOrdersUseCase returns repository orders', () async {
      final expected = [sampleOrderEntity(orderId: 'order-9')];
      final repository = TestOrderRepository(
        onGetMyOrders: () async => expected,
      );
      final usecase = GetMyOrdersUseCase(repository);

      final result = await usecase();

      expect(result, expected);
    });
  });
}
