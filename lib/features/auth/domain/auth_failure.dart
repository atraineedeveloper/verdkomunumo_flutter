import '../../../core/error/app_failure.dart';

class AuthFailure extends AppFailure {
  const AuthFailure(
    super.message, {
    super.kind = AppFailureKind.auth,
    super.cause,
  });
}
