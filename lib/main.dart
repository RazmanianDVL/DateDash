import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/id_verification_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/biometric_gate.dart'; // kept for optional use

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DateDash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(backgroundColor: Colors.deepPurple),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen(); // your existing login/signup screen
        }

        // User is logged in → check if they have completed ID verification
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};

            // Biometric is now OPTIONAL (we already added this flag earlier)
            final bool biometricEnabled = userData['biometricEnabled'] ?? false;

            // If they have NOT completed ID verification yet
            if (userData['isVerified'] != true) {
              return const IDVerificationScreen();
            }

            // Biometric optional check (only show if they turned it on)
            if (biometricEnabled) {
              return const BiometricGate(); // your existing biometric screen
            }

            // Everything is done → go to the new bottom-nav home
            return const MainNavigationScreen();
          },
        );
      },
    );
  }
}