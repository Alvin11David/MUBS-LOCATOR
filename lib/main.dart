import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mubs_locator/admin%20pages/admin_dashboard.dart';
import 'package:mubs_locator/admin%20pages/dashboards/add_place_screen.dart';
import 'package:mubs_locator/admin%20pages/dashboards/location_management.dart';
import 'package:mubs_locator/firebase_options.dart';
import 'package:mubs_locator/user%20pages/auth/forgot_password.dart';
import 'package:mubs_locator/user%20pages/auth/otp_screen.dart';
import 'package:mubs_locator/user%20pages/auth/set_password_screen.dart';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';
import 'package:mubs_locator/user%20pages/auth/sign_up.dart';
import 'package:mubs_locator/user%20pages/intro/onboarding_screen1.dart';
import 'package:mubs_locator/user%20pages/intro/onboarding_screen2.dart';
import 'package:mubs_locator/user%20pages/intro/onboarding_screen3.dart';
import 'package:mubs_locator/user%20pages/map%20screens/home_screen.dart';
import 'package:mubs_locator/user%20pages/map%20screens/location_select_screen.dart';
import 'package:mubs_locator/user%20pages/other%20screens/about_screen.dart';
import 'package:mubs_locator/user%20pages/other%20screens/edit_profile_screen.dart';
import 'package:mubs_locator/user%20pages/other%20screens/notification_screen.dart';
import 'package:mubs_locator/user%20pages/splash/splash_screen.dart';
import 'package:mubs_locator/user%20pages/other%20screens/profile_screen.dart';
import 'package:get/get.dart';
import 'package:mubs_locator/services/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Fire base initialized successfully');
  } catch (e) {
    print('Firebase init error: $e');
  }
  Get.put(NavigationService());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MUBS Locator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/LocationSelectScreen', // Start with splash screen
      routes: {
        '/OnboardingScreen1': (context) => const OnboardingScreen1(),
        '/OnboardingScreen2': (context) => const OnboardingScreen2(),
        '/OnboardingScreen3': (context) => const OnboardingScreen3(),
        '/SignInScreen': (context) => const SignInScreen(),
        '/SplashScreen': (context) => const SplashScreen(),
        '/SignUpScreen': (context) => const SignUpScreen(),
        '/ForgotPasswordScreen': (context) => const ForgotPasswordScreen(),
        '/LocationSelectScreen': (context) => const LocationSelectScreen(),
        '/AboutScreen': (context) => const AboutScreen(),
        '/EditProfileScreen': (context) => const EditProfileScreen(),
        '/AdminDashboardScreen': (context) => const AdminDashboardScreen(),
        '/LocationManagementScreen': (context) =>
            const LocationManagementScreen(),
        '/ProfileScreen': (context) => const ProfileScreen(),
        '/OTPScreen': (context) => const OTP_Screen(email: ''),
        '/ResetPasswordScreen': (context) => const ResetPasswordScreen(),
        '/NotificationsScreen': (context) => const NotificationsScreen(),
        '/AddPlaceScreen': (context) => const AddPlaceScreen(),
        '/HomeScreen': (context) => const HomeScreen(),
      },
    );
  }
}
