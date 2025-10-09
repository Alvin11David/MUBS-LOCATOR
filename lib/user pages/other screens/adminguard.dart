import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mubs_locator/user%20pages/auth/sign_in.dart';

class AdminGuard extends StatelessWidget {
  final Widget child;

  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print('AdminGuard: Checking user ${user?.uid}, email: ${user?.email} for route ${ModalRoute.of(context)?.settings.name}');

    if (user != null && user.email == 'adminuser@gmail.com') {
      print('AdminGuard: User is admin, rendering child');
      return child;
    } else {
      print('AdminGuard: User not admin or not logged in, redirecting to /SignInScreen');
      Future.microtask(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
  }
}