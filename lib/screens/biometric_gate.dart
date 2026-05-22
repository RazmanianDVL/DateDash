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

  Future<void> _authenticate() async {
    try {
      // Show exactly what the device supports
      final bool canCheck = await auth.canCheckBiometrics;
      final bool isSupported = await auth.isDeviceSupported();
      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();

      print("🔍 Biometrics debug:");
      print("canCheckBiometrics: $canCheck");
      print("isDeviceSupported: $isSupported");
      print("Available biometrics: $availableBiometrics");

      if (!canCheck || !isSupported || availableBiometrics.isEmpty) {
        Fluttertoast.showToast(msg: "No biometrics enrolled on this device");
        _continueToVerification();
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Unlock DateDash',
        options: const AuthenticationOptions(
          biometricOnly: false,      // ← changed to false so it can fall back
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 140, color: Colors.pinkAccent),
            const SizedBox(height: 40),
            const Text(
              'Quick Unlock',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Use fingerprint or face ID',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 80),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint, size: 32),
              label: const Text('UNLOCK WITH BIOMETRICS', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              ),
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: _continueToVerification,
              child: const Text(
                'Use password instead',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}