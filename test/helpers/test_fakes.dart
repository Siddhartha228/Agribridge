import 'package:agribridge/core/error/failures.dart';
import 'package:agribridge/core/services/security/biometric_auth_service.dart';
import 'package:agribridge/core/services/storage/user_session_service.dart';
import 'package:agribridge/features/auth/domain/entities/auth_entity.dart';
import 'package:agribridge/features/auth/domain/repositories/auth_repository.dart';
import 'package:agribridge/features/auth/domain/usecases/change_password_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/login_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/register_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/reset_forgot_password_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/send_forgot_password_otp_usecase.dart';
import 'package:agribridge/features/auth/domain/usecases/verify_forgot_password_otp_usecase.dart';
import 'package:agribridge/features/auth/presentation/view_model/auth_view_model.dart';
import 'package:agribridge/features/dashboard/domain/entities/home_entity.dart';
import 'package:agribridge/features/dashboard/domain/entities/order_entity.dart';
import 'package:agribridge/features/dashboard/domain/entities/profile_entity.dart';
import 'package:agribridge/features/dashboard/domain/repositories/home_repository.dart';
import 'package:agribridge/features/dashboard/domain/repositories/order_repository.dart';
import 'package:agribridge/features/dashboard/domain/repositories/profile_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestAuthRepository implements IAuthRepository {
  TestAuthRepository({
    this.onRegister,
    this.onLogin,
    this.onGetCurrentUser,
    this.onLogout,
    this.onChangePassword,
    this.onDeleteAccount,
    this.onSendForgotPasswordOtp,
    this.onVerifyForgotPasswordOtp,
    this.onResetForgotPassword,
  });

  Future<Either<Failure, bool>> Function(AuthEntity entity)? onRegister;
  Future<Either<Failure, AuthEntity>> Function(String email, String password)?
  onLogin;
  Future<Either<Failure, AuthEntity>> Function()? onGetCurrentUser;
  Future<Either<Failure, bool>> Function()? onLogout;
  Future<Either<Failure, bool>> Function(
    String userId,
    String currentPassword,
    String newPassword,
  )?
  onChangePassword;
  Future<Either<Failure, bool>> Function(String userId, String currentPassword)?
  onDeleteAccount;
  Future<Either<Failure, bool>> Function(String email)? onSendForgotPasswordOtp;
  Future<Either<Failure, bool>> Function(String email, String otp)?
  onVerifyForgotPasswordOtp;
  Future<Either<Failure, bool>> Function(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  )?
  onResetForgotPassword;

  @override
  Future<Either<Failure, bool>> register(AuthEntity entity) {
    if (onRegister != null) {
      return onRegister!(entity);
    }
    return Future.value(const Right(true));
  }

  @override
  Future<Either<Failure, AuthEntity>> login(String email, String password) {
    if (onLogin != null) {
      return onLogin!(email, password);
    }
    return Future.value(
      Right(
        sampleAuthEntity(
          authId: 'auth-1',
          fullName: 'Test User',
          email: email,
          username: email.split('@').first,
          password: password,
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, AuthEntity>> getCurrentUser() {
    if (onGetCurrentUser != null) {
      return onGetCurrentUser!();
    }
    return Future.value(Right(sampleAuthEntity()));
  }

  @override
  Future<Either<Failure, bool>> logout() {
    if (onLogout != null) {
      return onLogout!();
    }
    return Future.value(const Right(true));
  }

  @override
  Future<Either<Failure, bool>> changePassword(
    String userId,
    String currentPassword,
    String newPassword,
  ) {
    if (onChangePassword != null) {
      return onChangePassword!(userId, currentPassword, newPassword);
    }
    return Future.value(const Right(true));
  }

  @override
  Future<Either<Failure, bool>> deleteAccount(
    String userId,
    String currentPassword,
  ) {
    if (onDeleteAccount != null) {
      return onDeleteAccount!(userId, currentPassword);
    }
    return Future.value(const Right(true));
  }

  @override
  Future<Either<Failure, bool>> sendForgotPasswordOtp(String email) {
    if (onSendForgotPasswordOtp != null) {
      return onSendForgotPasswordOtp!(email);
    }
    return Future.value(const Right(true));
  }

  @override
  Future<Either<Failure, bool>> verifyForgotPasswordOtp(
    String email,
    String otp,
  ) {
    if (onVerifyForgotPasswordOtp != null) {
      return onVerifyForgotPasswordOtp!(email, otp);
    }
    return Future.value(const Right(true));
  }

  @override
  Future<Either<Failure, bool>> resetForgotPassword(
    String email,
    String otp,
    String newPassword,
    String confirmPassword,
  ) {
    if (onResetForgotPassword != null) {
      return onResetForgotPassword!(email, otp, newPassword, confirmPassword);
    }
    return Future.value(const Right(true));
  }
}

class TestHomeRepository implements HomeRepository {
  TestHomeRepository({this.onGetProducts});

  Future<List<HomeEntity>> Function()? onGetProducts;

  @override
  Future<List<HomeEntity>> getProducts() {
    if (onGetProducts != null) {
      return onGetProducts!();
    }
    return Future.value([sampleHomeEntity()]);
  }
}

class TestOrderRepository implements OrderRepository {
  TestOrderRepository({this.onGetMyOrders});

  Future<List<OrderEntity>> Function()? onGetMyOrders;

  @override
  Future<List<OrderEntity>> getMyOrders() {
    if (onGetMyOrders != null) {
      return onGetMyOrders!();
    }
    return Future.value([sampleOrderEntity()]);
  }
}

class TestProfileRepository implements ProfileRepository {
  TestProfileRepository({this.onSaveProfileImage, this.onGetProfile});

  Future<void> Function(String imagePath, String customerId)? onSaveProfileImage;
  Future<ProfileEntity?> Function(String customerId)? onGetProfile;

  @override
  Future<void> saveProfileImage(String imagePath, String customerId) {
    if (onSaveProfileImage != null) {
      return onSaveProfileImage!(imagePath, customerId);
    }
    return Future.value();
  }

  @override
  Future<ProfileEntity?> getProfile(String customerId) {
    if (onGetProfile != null) {
      return onGetProfile!(customerId);
    }
    return Future.value(sampleProfileEntity());
  }
}

class TestUserSessionService extends UserSessionService {
  TestUserSessionService({
    required SharedPreferences prefs,
    this.currentUserId = 'user-1',
    this.currentUserEmail = 'test@example.com',
    this.currentUserFullName = 'Test User',
    this.currentUserPhoneNumber = '',
    this.currentUserAddress = '',
    this.biometricEnabled = false,
    this.biometricCredentialsAvailable = false,
    this.throwOnSaveBiometricCredentials = false,
  }) : super(prefs: prefs);

  String? currentUserId;
  String? currentUserEmail;
  String? currentUserFullName;
  String? currentUserPhoneNumber;
  String? currentUserAddress;
  bool biometricEnabled;
  bool biometricCredentialsAvailable;
  bool throwOnSaveBiometricCredentials;

  int syncBiometricStateAfterLoginCalls = 0;
  int saveBiometricCredentialsCalls = 0;
  final Map<String, String> savedCarts = {};

  @override
  String? getCurrentUserId() => currentUserId;

  @override
  String? getCurrentUserEmail() => currentUserEmail;

  @override
  String? getCurrentUserFullName() => currentUserFullName;

  @override
  String? getCurrentUserPhoneNumber() => currentUserPhoneNumber;

  @override
  String? getCurrentUserAddress() => currentUserAddress;

  @override
  bool isBiometricLoginEnabled() => biometricEnabled;

  @override
  bool isBiometricLoginEnabledForCurrentUser() => biometricEnabled;

  @override
  Future<void> setBiometricLoginEnabled(bool enabled) async {
    biometricEnabled = enabled;
  }

  @override
  Future<bool> hasBiometricCredentials() async => biometricCredentialsAvailable;

  @override
  Future<bool> hasBiometricCredentialsForCurrentUser() async {
    return biometricCredentialsAvailable;
  }

  @override
  Future<void> syncBiometricStateAfterLogin({
    required String loggedInUserId,
  }) async {
    syncBiometricStateAfterLoginCalls += 1;
  }

  @override
  Future<void> saveBiometricCredentials({
    required String email,
    required String password,
  }) async {
    saveBiometricCredentialsCalls += 1;
    if (throwOnSaveBiometricCredentials) {
      throw Exception('Failed to save biometric credentials');
    }
  }

  @override
  Future<void> setCurrentUserPhoneNumber(String? phoneNumber) async {
    currentUserPhoneNumber = phoneNumber;
  }

  @override
  Future<void> setCurrentUserAddress(String? address) async {
    currentUserAddress = address;
  }

  @override
  Future<void> saveCartForUser({
    required String userId,
    required String cartJson,
  }) async {
    savedCarts[userId] = cartJson;
  }

  @override
  String? getCartForUser(String userId) => savedCarts[userId];

  @override
  Future<void> clearSession() async {
    currentUserId = null;
    currentUserEmail = null;
    currentUserFullName = null;
    currentUserPhoneNumber = null;
    currentUserAddress = null;
  }
}

class TestBiometricAuthService extends BiometricAuthService {
  TestBiometricAuthService({
    this.canUseBiometricLoginResult = false,
    this.authenticateResult = true,
  }) : super(localAuthentication: LocalAuthentication());

  bool canUseBiometricLoginResult;
  bool authenticateResult;

  @override
  Future<bool> canUseBiometricLogin() async => canUseBiometricLoginResult;

  @override
  Future<bool> authenticate({required String reason}) async {
    return authenticateResult;
  }
}

AuthViewModel buildTestAuthViewModel({
  required IAuthRepository repository,
  required UserSessionService userSessionService,
}) {
  return AuthViewModel(
    loginUsecase: LoginUsecase(authRepository: repository),
    registerUsecase: RegisterUsecase(authRepository: repository),
    changePasswordUsecase: ChangePasswordUsecase(authRepository: repository),
    deleteAccountUsecase: DeleteAccountUsecase(authRepository: repository),
    sendForgotPasswordOtpUsecase: SendForgotPasswordOtpUsecase(
      authRepository: repository,
    ),
    verifyForgotPasswordOtpUsecase: VerifyForgotPasswordOtpUsecase(
      authRepository: repository,
    ),
    resetForgotPasswordUsecase: ResetForgotPasswordUsecase(
      authRepository: repository,
    ),
    userSessionService: userSessionService,
  );
}

AuthEntity sampleAuthEntity({
  String? authId,
  String fullName = 'Test User',
  String email = 'test@example.com',
  String username = 'test_user',
  String? password = 'password123',
  String? profilePicture,
}) {
  return AuthEntity(
    authId: authId,
    fullName: fullName,
    email: email,
    username: username,
    password: password,
    profilePicture: profilePicture,
  );
}

HomeEntity sampleHomeEntity({
  String id = 'p1',
  String name = 'Tomato',
  double price = 120,
  int quantity = 10,
  String image = 'assets/images/agri_logo.png',
  String category = 'Vegetable',
  String description = 'Fresh tomato',
  String unit = 'Kg',
  String availability = 'in-stock',
}) {
  return HomeEntity(
    id: id,
    name: name,
    price: price,
    quantity: quantity,
    image: image,
    category: category,
    description: description,
    unit: unit,
    availability: availability,
  );
}

OrderEntity sampleOrderEntity({
  String userId = 'user-1',
  String orderId = 'order-1',
  String productId = 'product-1',
  String productName = 'Tomato',
  String customerName = 'Test User',
  String deliveryAddress = 'Kathmandu',
  String imagePath = 'assets/images/agri_logo.png',
  double pricePerUnit = 120,
  int quantity = 2,
  double total = 240,
  double orderSubtotal = 240,
  double deliveryFee = 120,
  String status = 'pending',
  String unit = 'Kg',
  DateTime? createdAt,
}) {
  return OrderEntity(
    userId: userId,
    orderId: orderId,
    productId: productId,
    productName: productName,
    customerName: customerName,
    deliveryAddress: deliveryAddress,
    imagePath: imagePath,
    pricePerUnit: pricePerUnit,
    quantity: quantity,
    total: total,
    orderSubtotal: orderSubtotal,
    deliveryFee: deliveryFee,
    status: status,
    unit: unit,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

ProfileEntity sampleProfileEntity({
  String? name = 'Test User',
  String? email = 'test@example.com',
  String? imagePath = 'assets/images/agri_logo.png',
}) {
  return ProfileEntity(name: name, email: email, imagePath: imagePath);
}
