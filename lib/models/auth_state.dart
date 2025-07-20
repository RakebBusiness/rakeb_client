enum AppAuthStatus {
  initial,
  loading,
  codeSent,
  verified,
  error,
  authenticated,
  unauthenticated
}

class AppAuthState {
  final AppAuthStatus status;
  final String? error;
  final String? verificationId;
  final String? phoneNumber;
  final String? userId;

  const AppAuthState({
    this.status = AppAuthStatus.initial,
    this.error,
    this.verificationId,
    this.phoneNumber,
    this.userId,
  });

  AppAuthState copyWith({
    AppAuthStatus? status,
    String? error,
    String? verificationId,
    String? phoneNumber,
    String? userId,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      error: error,
      verificationId: verificationId ?? this.verificationId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      userId: userId ?? this.userId,
    );
  }
}