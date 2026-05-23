import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'id_verification_screen.dart';

class BiometricGate extends StatefulWidget {
  const BiometricGate({super.key});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  Future<void> _authenticate() async {
    setState(() => _isAuthenticating = true);

    try {
      final bool canCheck = await auth.canCheckBiometrics;
      final bool isSupported = await auth.isDeviceSupported();
      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();

      if (!canCheck || !isSupported || availableBiometrics.isEmpty) {
        Fluttertoast.showToast(msg: "No biometrics enrolled on this device");
        _continueToVerification();
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Unlock DateDash',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        Fluttertoast.showToast(msg: "✅ Biometrics unlocked!");
        _continueToVerification();
      } else {
        Fluttertoast.showToast(msg: "Biometrics cancelled");
      }
    } catch (e) {
      print("Biometrics error: $e");
      Fluttertoast.showToast(msg: "Biometrics unavailable — using password");
      _continueToVerification();
    } finally {
      setState(() => _isAuthenticating = false);
    }
  }

  void _continueToVerification() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const IDVerificationGate()),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B1B5E), Color(0xFF2C0A4D), Colors.black87],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Large animated fingerprint icon
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 120,
                      color: Colors.pinkAccent,
                    ),
                  ),
                  const SizedBox(height: 48),

                  const Text(
                    'Quick Unlock',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Use fingerprint or face ID to continue',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 80),

                  // Unlock button
                  SizedBox(
                    width: double.infinity,
                    height: 66,
                    child: ElevatedButton.icon(
                      onPressed: _isAuthenticating ? null : _authenticate,
                      icon: const Icon(Icons.fingerprint, size: 32),
                      label: const Text(
                        'UNLOCK WITH BIOMETRICS',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Fallback option
                  TextButton(
                    onPressed: _continueToVerification,
                    child: const Text(
                      'Use password instead',
                      style: TextStyle(fontSize: 18, color: Colors.white70),
                    ),
                  ),

                  if (_isAuthenticating)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: CircularProgressIndicator(color: Colors.pinkAccent),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}