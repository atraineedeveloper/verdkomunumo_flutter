enum AppFailureKind {
  unknown,
  auth,
  validation,
  permission,
  notFound,
  conflict,
  network,
  backend,
}

class AppFailure implements Exception {
  final String message;
  final AppFailureKind kind;
  final Object? cause;

  const AppFailure(
    this.message, {
    this.kind = AppFailureKind.unknown,
    this.cause,
  });

  @override
  String toString() => message;
}

String failureMessageOf(Object error, {required String fallback}) {
  if (error is AppFailure && error.message.trim().isNotEmpty) {
    return error.message;
  }

  return fallback;
}
