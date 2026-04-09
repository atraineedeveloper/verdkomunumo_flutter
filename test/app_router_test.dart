import 'package:flutter_test/flutter_test.dart';
import 'package:verdkomunumo_flutter/app/routing/app_router.dart';
import 'package:verdkomunumo_flutter/app/routing/app_routes.dart';

void main() {
  group('resolveAuthRedirect', () {
    test('redirects unauthenticated users away from protected routes', () {
      expect(
        resolveAuthRedirect(
          isAuthenticated: false,
          matchedLocation: AppRoutes.settings,
        ),
        AppRoutes.login,
      );
      expect(
        resolveAuthRedirect(
          isAuthenticated: false,
          matchedLocation: AppRoutes.notifications,
        ),
        AppRoutes.login,
      );
    });

    test('redirects authenticated users away from auth screens', () {
      expect(
        resolveAuthRedirect(
          isAuthenticated: true,
          matchedLocation: AppRoutes.login,
        ),
        AppRoutes.feed,
      );
      expect(
        resolveAuthRedirect(
          isAuthenticated: true,
          matchedLocation: AppRoutes.register,
        ),
        AppRoutes.feed,
      );
    });

    test('does not redirect routes when access is valid', () {
      expect(
        resolveAuthRedirect(
          isAuthenticated: false,
          matchedLocation: AppRoutes.feed,
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          isAuthenticated: true,
          matchedLocation: AppRoutes.settings,
        ),
        isNull,
      );
    });
  });
}
