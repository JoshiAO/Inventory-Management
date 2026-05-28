import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../data/models/user_model.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showUserDialog(context),
          ),
        ],
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: adminProvider.users.length,
              itemBuilder: (context, index) {
                final user = adminProvider.users[index];
                return ListTile(
                  title: Text(user.email),
                  subtitle: Text('Role: ${user.role} | Cat: ${user.assignedCategory}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showUserDialog(context, user: user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => adminProvider.deleteUser(user.uid),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showUserDialog(BuildContext context, {UserModel? user}) {
    final emailController = TextEditingController(text: user?.email ?? '');
    final uidController = TextEditingController(text: user?.uid ?? '');
    final categoryController = TextEditingController(text: user?.assignedCategory ?? '');
    String selectedRole = user?.role ?? 'user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? 'Create User' : 'Edit User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: uidController,
                decoration: const InputDecoration(labelText: 'UID (from Auth)'),
                enabled: user == null,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'superuser', child: Text('Superuser')),
                ],
                onChanged: (v) => selectedRole = v!,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Assigned Category'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newUser = UserModel(
                uid: uidController.text.trim(),
                email: emailController.text.trim(),
                role: selectedRole,
                assignedCategory: categoryController.text.trim(),
              );
              context.read<AdminProvider>().saveUser(newUser);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
