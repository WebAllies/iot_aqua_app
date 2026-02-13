import 'package:flutter/material.dart';
import 'manage_roles_page.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Super Admin Dashboard 👑")),
      body: Center(
        child: ElevatedButton(
          child: const Text("Manage User Roles"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageRolesPage()),
            );
          },
        ),
      ),
    );
  }
}
