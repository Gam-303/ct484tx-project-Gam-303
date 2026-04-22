import 'package:go_router/go_router.dart';

import '../services/cubits/auth_cubit.dart';
import '../ui/analytics/stats_screen.dart';
import '../ui/auth/forgot_password_screen.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/change_password_screen.dart';
import '../ui/auth/register_screen.dart';
import '../ui/auth/reset_password_screen.dart';
import '../ui/auth/verify_otp_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/home/task_detail_screen.dart';
import '../ui/home/task_editor_screen.dart';
import '../ui/notification/notification_screen.dart';
import '../ui/notification/pomodoro_timer_screen.dart';
import '../ui/profile/profile_screen.dart';
import '../ui/profile/settings_screen.dart';
import '../ui/shell/main_shell.dart';
import '../ui/shell/splash_screen.dart';
import 'router_refresh_stream.dart';

GoRouter buildRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final loggedIn = authCubit.state.loggedIn;
      final atAuth = <String>{
        '/login',
        '/register',
        '/forgot-password',
        '/verify-otp',
        '/reset-password',
      }.contains(state.matchedLocation);
      if (!loggedIn && !atAuth && state.matchedLocation != '/splash') {
        return '/login';
      }
      if (loggedIn && atAuth) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final extra =
              state.extra as Map<String, dynamic>? ?? const <String, dynamic>{};
          return VerifyOtpScreen(email: (extra['email'] ?? '') as String);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final extra =
              state.extra as Map<String, dynamic>? ?? const <String, dynamic>{};
          return ResetPasswordScreen(email: (extra['email'] ?? '') as String);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'task/new',
                    builder: (context, state) => const TaskEditorScreen(),
                  ),
                  GoRoute(
                    path: 'task/:taskId/edit',
                    builder: (context, state) => TaskEditorScreen(
                      taskId: state.pathParameters['taskId'],
                    ),
                  ),
                  GoRoute(
                    path: 'task/:taskId',
                    builder: (context, state) => TaskDetailScreen(
                      taskId: state.pathParameters['taskId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/timer',
                builder: (context, state) => const PomodoroTimerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
