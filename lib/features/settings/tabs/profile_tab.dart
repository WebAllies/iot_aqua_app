import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileTab extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(name.isEmpty ? "No Name" : name),
            subtitle: Text(email),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text("Account Role"),
            subtitle: Text(role),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text("Change Password"),
            subtitle: const Text("Send reset link to your email"),
            onTap: () async {
              final userEmail = FirebaseAuth.instance.currentUser?.email;
              if (userEmail == null) return;

              await FirebaseAuth.instance.sendPasswordResetEmail(email: userEmail);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password reset email sent.")),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: onLogout,
          ),
        ),
      ],
    );
  }
}
