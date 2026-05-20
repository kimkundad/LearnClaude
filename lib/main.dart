import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
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
import 'screens/exam_v2_screen.dart';
import 'screens/exam_v2_list_screen.dart';
import 'screens/all_packages_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/articles_screen.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/phone_otp_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    final loc = state.matchedLocation;
    final isLoginPage = loc == '/login' || loc == '/register';
    final isPublicPage = isLoginPage ||
        loc == '/forgot-password' ||
        loc == '/otp' ||
        loc == '/set-password' ||
        loc == '/complete-profile' ||
        loc == '/phone-otp';

    if (!loggedIn && !isPublicPage) return '/login';

    if (loggedIn && !isPublicPage) {
      final complete = await AuthService.instance.isProfileComplete();
      if (!complete) return '/complete-profile';
    }

    if (loggedIn && isLoginPage) {
      final complete = await AuthService.instance.isProfileComplete();
      return complete ? '/home' : '/complete-profile';
    }

    return null;
  },
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
      builder: (context, state) {
        final extra = (state.extra as Map?)?.cast<String, String>() ?? {};
        return SetPasswordScreen(
          email: extra['email'] ?? '',
          resetToken: extra['reset_token'] ?? '',
        );
      },
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
      builder: (context, state) => CourseDetailScreen(
        courseData: state.extra as Map<String, dynamic>?,
      ),
    ),
    GoRoute(
      path: '/packages',
      builder: (context, state) => const AllPackagesScreen(),
    ),
    GoRoute(
      path: '/package',
      builder: (context, state) => PackageDetailScreen(
        packageId: (state.extra as int?) ?? 0,
      ),
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/articles',
      builder: (context, state) => const ArticlesScreen(),
    ),
    GoRoute(
      path: '/complete-profile',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: '/phone-otp',
      builder: (context, state) {
        final extra = (state.extra as Map?)?.cast<String, dynamic>() ?? {};
        return PhoneOtpScreen(
          phone: extra['phone'] as String? ?? state.extra as String? ?? '',
          phoneCode: extra['phoneCode'] as String? ?? '',
        );
      },
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
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return VideoPlayerScreen(
          courseId: extra?['courseId'] as int? ?? 0,
          courseTitle: extra?['title'] as String? ?? 'บทเรียน',
        );
      },
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PaymentScreen(
          courseTitle: extra?['title'] as String? ?? 'คอร์สเรียน',
          price: extra?['price'] as int? ?? 3950,
          itemId: extra?['id'] as int? ?? 0,
          itemType: extra?['type'] as String? ?? 'package',
        );
      },
    ),
    GoRoute(
      path: '/payment-success',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PaymentSuccessScreen(
          courseTitle: extra?['title'] as String? ?? 'คอร์สเรียน',
          price: (extra?['price'] as num?)?.toInt() ?? 0,
        );
      },
    ),
    GoRoute(
      path: '/quiz',
      builder: (context, state) => QuizScreen(
        quizTitle: state.extra as String? ?? 'แบบฝึกหัด',
      ),
    ),
    GoRoute(
      path: '/exam-v2',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ExamV2Screen(
          exerciseId:    (extra['exerciseId'] as int?) ?? 0,
          exerciseTitle: (extra['exerciseTitle'] as String?) ?? 'แบบทดสอบ',
          saveAttempt:   (extra['saveAttempt'] as bool?) ?? false,
        );
      },
    ),
    GoRoute(
      path: '/exam-v2-list',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ExamV2ListScreen(
          courseId:    (extra['courseId'] as int?) ?? 0,
          courseTitle: (extra['courseTitle'] as String?) ?? 'คอร์สเรียน',
        );
      },
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
