import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mubs_locator/admin%20pages/admin_dashboard.dart';
import 'package:mubs_locator/admin%20pages/dashboards/add_place_screen.dart';
import 'package:mubs_locator/admin%20pages/dashboards/edit_place_screen.dart';
import 'package:mubs_locator/admin%20pages/dashboards/feedback_details_screen.dart';
import 'package:mubs_locator/admin%20pages/dashboards/feedback_list_screen.dart';
import 'package:mubs_locator/admin%20pages/dashboards/location_management.dart';
import 'package:mubs_locator/admin%20pages/dashboards/send_notifications_screen.dart';
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
import 'package:mubs_locator/user%20pages/other%20screens/adminguard.dart';
import 'package:mubs_locator/user%20pages/other%20screens/edit_profile_screen.dart';
import 'package:mubs_locator/user%20pages/other%20screens/feedback_screen.dart';
import 'package:mubs_locator/user%20pages/other%20screens/notification_screen.dart';
import 'package:mubs_locator/user%20pages/other%20screens/terms_and_privacy_screen.dart';
import 'package:mubs_locator/user%20pages/splash/splash_screen.dart';
import 'package:mubs_locator/user%20pages/other%20screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase init error: $e');
  }
  runApp(const MyApp());
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
      home: const SplashScreen(),
      initialRoute: '/SplashScreen',
      routes: {
        '/OnboardingScreen1': (context) => const OnboardingScreen1(),
        '/OnboardingScreen2': (context) => const OnboardingScreen2(),
        '/OnboardingScreen3': (context) => const OnboardingScreen3(),
        '/SignInScreen': (context) => const SignInScreen(),
        '/SplashScreen': (context) => const SplashScreen(),
        '/SignUpScreen': (context) => const SignUpScreen(),
        '/ForgotPasswordScreen': (context) => const ForgotPasswordScreen(),
        '/LocationSelectScreen': (context) => const LocationSelectScreen(),
        '/FeedbackScreen': (context) => const FeedbackScreen(),
        '/AboutScreen': (context) => const AboutScreen(),
        '/Terms&PrivacyScreen': (context) => const TermsAndPrivacyScreen(),
        '/EditProfileScreen': (context) => const EditProfileScreen(),
        '/AdminDashboardScreen': (context) =>
            AdminGuard(child: const AdminDashboardScreen()),
        '/LocationManagementScreen': (context) =>
            AdminGuard(child: const LocationManagementScreen()),
        '/AddPlaceScreen': (context) =>
            AdminGuard(child: const AddPlaceScreen()),
        '/EditPlaceScreen': (context) =>
            AdminGuard(child: const EditPlaceScreen(buildingId: '',)),
        '/FeedbackListScreen': (context) => 
            AdminGuard(child: const FeedbackListScreen()),
        '/SendNotificationsScreen': (context) =>
        AdminGuard(child: const SendNotificationScreen()),
        '/FeedbackDetailsScreen': (context) => FeedbackDetailsScreen(feedbackId: '',),
        '/ProfileScreen': (context) => const ProfileScreen(),
        '/ResetPasswordScreen': (context) =>
            const ResetPasswordScreen(email: ''),
        '/NotificationsScreen': (context) => const NotificationsScreen(),
        '/HomeScreen': (context) => const HomeScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/OTPScreen') {
          final email = settings.arguments as String? ?? '';
          return MaterialPageRoute(
            builder: (context) => OTP_Screen(email: email),
          );
        }
        return null;
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}