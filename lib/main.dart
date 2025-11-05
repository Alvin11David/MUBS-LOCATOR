import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
import 'package:get/get.dart';
import 'package:mubs_locator/services/navigation_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // FCM handles notification display in the notification bar
}

// Global NavigatorKey for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode
      ? AndroidProvider.debug          // Local testing (flutter run)
      : AndroidProvider.playIntegrity, // Play Store (release)
);
await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(false);
    // Initialize flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await FlutterLocalNotificationsPlugin().initialize(initializationSettings);
    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'mubs_locator_notifications', // Channel ID
      'MUBS Locator Notifications', // Channel name
      description: 'Notifications for MUBS Locator app',
      importance: Importance.max,
    );
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    // Set up FCM background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // Request notification permissions (Android 13+)
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
    // Initialize FCM and save token
    final messaging = FirebaseMessaging.instance;
    await _saveFcmToken();
    await messaging.subscribeToTopic('all_users');
    // Handle token refresh
    messaging.onTokenRefresh.listen((token) {
      _saveFcmToken();
    });
    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
    // Handle notification tap (background/terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['type'] == 'feedback_reply') {
        final feedbackId = message.data['feedbackId'];
        if (feedbackId != null) {
          navigatorKey.currentState?.pushNamed(
            '/FeedbackDetailsScreen',
            arguments: feedbackId,
          );
        }
      } else {
        // Default to NotificationsScreen for other notifications
        navigatorKey.currentState?.pushNamed('/NotificationsScreen');
      }
    });
    // Handle initial message (app opened from terminated state)
    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (message.data['type'] == 'feedback_reply') {
          final feedbackId = message.data['feedbackId'];
          if (feedbackId != null) {
            navigatorKey.currentState?.pushNamed(
              '/FeedbackDetailsScreen',
              arguments: feedbackId,
            );
          }
        } else {
          navigatorKey.currentState?.pushNamed('/NotificationsScreen');
        }
      }
    });
  } catch (e) {
    //
  }
  Get.put(NavigationService());
  runApp(const MyApp());
}

// Function to save FCM token to Firestore
Future<void> _saveFcmToken() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    }
  } catch (e) {
    //
  }
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
      navigatorKey:
          navigatorKey, // Add navigatorKey for notification navigation
      home: const SplashScreen(),
      initialRoute: '/SplashScreen',
      routes: {
        '/SplashScreen': (context) => const SplashScreen(),
        '/OnboardingScreen1': (context) => const OnboardingScreen1(),
        '/OnboardingScreen2': (context) => const OnboardingScreen2(),
        '/OnboardingScreen3': (context) => const OnboardingScreen3(),
        '/SignInScreen': (context) => const SignInScreen(),
        '/SignUpScreen': (context) => const SignUpScreen(),
        '/ForgotPasswordScreen': (context) => const ForgotPasswordScreen(),
        '/HomeScreen': (context) => const HomeScreen(),
        '/LocationSelectScreen': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final String? buildingName = args?['buildingName'] as String?;
          return LocationSelectScreen(
            onDirectionsTap: () {},
            initialDestinationName: buildingName,
          );
        },
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
        '/EditPlaceScreen': (context) => AdminGuard(
          child: EditPlaceScreen(
            buildingId:
                (ModalRoute.of(context)!.settings.arguments as String?) ?? '',
          ),
        ),
        '/FeedbackListScreen': (context) =>
            AdminGuard(child: const FeedbackListScreen()),
        '/SendNotificationsScreen': (context) =>
            AdminGuard(child: const SendNotificationScreen()),
        '/FeedbackDetailsScreen': (context) => FeedbackDetailsScreen(
          feedbackId:
              (ModalRoute.of(context)!.settings.arguments as String?) ?? '',
        ),
        '/ProfileScreen': (context) => const ProfileScreen(),
        '/ResetPasswordScreen': (context) => ResetPasswordScreen(
          email: (ModalRoute.of(context)!.settings.arguments as String?) ?? '',
        ),
        '/NotificationsScreen': (context) => const NotificationsScreen(),
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

// MyHomePage remains unchanged
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
