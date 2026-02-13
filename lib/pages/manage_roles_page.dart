import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageRolesPage extends StatelessWidget {
  const ManageRolesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage User Roles")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final role = user["role"];
              final email = user["email"];

              // Super admin cannot be changed
              if (email == "superadmin@iot.com") {
                return ListTile(
                  title: Text(email),
                  subtitle: const Text("Super Admin 👑"),
                );
              }

              return ListTile(
                title: Text(email),
                subtitle: DropdownButton<String>(
                  value: role,
                  items: const [
                    DropdownMenuItem(
                        value: "employee", child: Text("Employee")),
                    DropdownMenuItem(
                        value: "admin", child: Text("Admin")),
                  ],
                  onChanged: (newRole) {
                    FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.id)
                        .update({"role": newRole});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
