import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple.shade900,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A0033), Color(0xFF2C0A4D), Colors.black87],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Account',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              subtitle: 'Photos, bio, and preferences',
              onTap: () => Navigator.pop(context),
            ),

            const SizedBox(height: 32),

            const Text(
              'App Preferences',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(icon: Icons.notifications_none, title: 'Notifications', subtitle: 'Push alerts and messages'),
            _buildSettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privacy & Safety', subtitle: 'Who can see you and contact you'),
            _buildSettingsTile(icon: Icons.location_on_outlined, title: 'Location', subtitle: 'Manage location sharing'),
            _buildSettingsTile(icon: Icons.block, title: 'Blocked Users', subtitle: 'Manage your block list'),

            const SizedBox(height: 32),

            const Text(
              'Support & Legal',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            _buildSettingsTile(icon: Icons.help_outline, title: 'Help Center', subtitle: 'Get support or report a problem'),
            _buildSettingsTile(icon: Icons.gavel, title: 'Terms of Service', subtitle: ''),
            _buildSettingsTile(icon: Icons.privacy_tip, title: 'Privacy Policy', subtitle: ''),

            const SizedBox(height: 60),

            // Logout
            SizedBox(
              width: double.infinity,
              height: 62,
              child: ElevatedButton(
                onPressed: () {
                  Fluttertoast.showToast(msg: "Logged out successfully");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Log Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: Colors.white.withOpacity(0.08),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        leading: Icon(icon, color: Colors.pinkAccent, size: 28),
        title: Text(title, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(color: Colors.white70)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }
}