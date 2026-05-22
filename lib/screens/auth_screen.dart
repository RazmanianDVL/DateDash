import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _validateStrongPassword(String password) {
    if (password.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(password)) return 'Must contain uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(password)) return 'Must contain lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Must contain a number';
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Must contain a special character';
    }
    return null;
  }

  Future<void> _handleAuth() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        Fluttertoast.showToast(msg: "Logged in successfully!");
      } else {
        final passwordError = _validateStrongPassword(_passwordController.text);
        if (passwordError != null) {
          Fluttertoast.showToast(msg: passwordError);
          return;
        }
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        Fluttertoast.showToast(msg: "Account created! Welcome to DateDash");
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "Authentication failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'DateDash',
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
            ),
            const SizedBox(height: 10),
            Text(
              isLogin ? 'Sign in to start random matching' : 'Create account (18+)',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            if (!isLogin)
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone number (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isLogin ? 'LOGIN' : 'CREATE ACCOUNT',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(
                isLogin ? "Don't have an account? Sign up" : "Already have an account? Login",
                style: const TextStyle(color: Colors.pinkAccent),
              ),
            ),

            const SizedBox(height: 30),
            const Text(
              'Fingerprint / Face ID unlock\nwill be enabled after first login',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}