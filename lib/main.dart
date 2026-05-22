import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth_screen.dart';
import 'screens/id_verification_screen.dart';
import 'screens/biometric_gate.dart';   // new

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCIBfFMdvd9cV7CmvZThgTqiJrDM0PTV74",
      appId: "1:36147853184:android:e9e3daa8ce692729c07365",
      messagingSenderId: "36147853184",
      projectId: "this-thing-f97e1",
      storageBucket: "this-thing-f97e1.firebasestorage.app",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DateDash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.pinkAccent,
        scaffoldBackgroundColor: Colors.black87,
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
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)));
        }
        if (snapshot.hasData) {
          return const BiometricGate();   // ← new biometric check
        }
        return const AuthScreen();
      },
    );
  }
}