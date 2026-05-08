import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/otp_screen.dart';
import 'screens/set_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/package_detail_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/about_us_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/video_player_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/payment_success_screen.dart';
import 'screens/quiz_screen.dart';

void main() {
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) =>
          OTPScreen(email: state.extra as String? ?? 'your@email.com'),
    ),
    GoRoute(
      path: '/set-password',
      builder: (context, state) => const SetPasswordScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/course',
      builder: (context, state) => const CourseDetailScreen(),
    ),
    GoRoute(
      path: '/package',
      builder: (context, state) => const PackageDetailScreen(),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/about-us',
      builder: (context, state) => const AboutUsScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: '/video',
      builder: (context, state) => const VideoPlayerScreen(),
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PaymentScreen(
          courseTitle: extra?['title'] as String? ?? 'คอร์สเรียน',
          price: extra?['price'] as int? ?? 3950,
        );
      },
    ),
    GoRoute(
      path: '/payment-success',
      builder: (context, state) => PaymentSuccessScreen(
        courseTitle: state.extra as String? ?? 'คอร์สเรียน',
      ),
    ),
    GoRoute(
      path: '/quiz',
      builder: (context, state) => QuizScreen(
        quizTitle: state.extra as String? ?? 'แบบฝึกหัด',
      ),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ครูพี่โฮม',
      theme: AppTheme.theme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th'),
        Locale('en'),
      ],
    );
  }
}
