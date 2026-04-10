import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_failure.dart';

AppFailureKind _kindFromStatus(String? statusCode) {
  switch (statusCode) {
    case '400':
      return AppFailureKind.validation;
    case '401':
    case '403':
      return AppFailureKind.permission;
    case '404':
      return AppFailureKind.notFound;
    case '409':
      return AppFailureKind.conflict;
    default:
      return AppFailureKind.backend;
  }
}

AppFailure mapSupabaseFailure(
  Object error, {
  required String fallbackMessage,
  AppFailureKind defaultKind = AppFailureKind.backend,
}) {
  if (error is AppFailure) {
    return error;
  }

  if (error is AuthException) {
    return AppFailure(error.message, kind: AppFailureKind.auth, cause: error);
  }

  if (error is PostgrestException) {
    return AppFailure(
      error.message,
      kind: _kindFromStatus(error.code),
      cause: error,
    );
  }

  if (error is StorageException) {
    return AppFailure(
      error.message,
      kind: AppFailureKind.backend,
      cause: error,
    );
  }

  return AppFailure(fallbackMessage, kind: defaultKind, cause: error);
}
