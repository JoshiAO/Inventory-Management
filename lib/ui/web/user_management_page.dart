import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../providers/admin_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/models/facility_model.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('System Users'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: ElevatedButton.icon(
              onPressed: () => _showUserDialog(context),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('CREATE NEW USER'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
      body: adminProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(32.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: ListView.separated(
                    itemCount: adminProvider.users.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = adminProvider.users[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        leading: CircleAvatar(
                          backgroundColor: user.role == 'superuser' 
                              ? AppTheme.keneaPrimary.withOpacity(0.1) 
                              : Colors.grey.shade100,
                          child: Icon(
                            user.role == 'superuser' ? Icons.admin_panel_settings : Icons.person,
                            color: user.role == 'superuser' ? AppTheme.keneaPrimary : Colors.grey.shade600,
                          ),
                        ),
                        title: Text(
                          user.name.isEmpty ? user.email : user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _buildBadge(user.role.toUpperCase(), 
                                      user.role == 'superuser' ? AppTheme.keneaPrimary : Colors.grey.shade600),
                                  if (user.facilityId.isNotEmpty)
                                    _buildBadge(
                                      adminProvider.facilities.firstWhere((f) => f.id == user.facilityId, orElse: () => Facility(id: '', name: 'Unknown', location: '')).name,
                                      Colors.indigo,
                                      icon: Icons.location_on,
                                    ),
                                  _buildBadge(
                                    _summarizeCategories(user.assignedCategories),
                                    Colors.blueGrey,
                                    icon: Icons.category,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                              onPressed: () => _showUserDialog(context, user: user),
                              tooltip: 'Edit User',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.lock_reset_outlined, color: Colors.orange),
                              onPressed: () => _confirmReset(context, adminProvider, user),
                              tooltip: 'Reset Password',
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                              onPressed: () => _confirmDelete(context, adminProvider, user),
                              tooltip: 'Delete User',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
  }

  String _summarizeCategories(List<String> cats) {
    if (cats.isEmpty) return 'No Categories';
    if (cats.length <= 2) return cats.join(', ');
    return '${cats[0]}, ${cats[1]} +${cats.length - 2} more';
  }

  Widget _buildBadge(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AdminProvider provider, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Are you sure you want to delete ${user.name} (${user.email})? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteUser(user.uid);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, AdminProvider provider, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset User Password?'),
        content: Text('Send a password reset email to ${user.name} (${user.email})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await provider.sendResetEmail(user.email);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reset email sent to ${user.email}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
                  );
                }
              }
            },
            child: const Text('SEND RESET EMAIL'),
          ),
        ],
      ),
    );
  }

  void _showUserDialog(BuildContext context, {UserModel? user}) {
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    List<String> selectedCategories = List.from(user?.assignedCategories ?? []);
    String selectedRole = user?.role ?? 'user';
    String selectedFacility = user?.facilityId ?? (context.read<AdminProvider>().facilities.isNotEmpty ? context.read<AdminProvider>().facilities.first.id : '');
    bool showCategoryPanel = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Register New User' : 'Edit User Profile'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Container(
            width: showCategoryPanel ? 800 : 400,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        TextField(controller: nameController),
                        const SizedBox(height: 20),
                        const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        TextField(controller: emailController, enabled: user == null),
                        if (user == null) ...[
                          const SizedBox(height: 20),
                          const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          TextField(controller: passwordController, obscureText: true),
                        ],
                        const SizedBox(height: 20),
                        const Text('System Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          items: const [
                            DropdownMenuItem(value: 'user', child: Text('Standard User')),
                            DropdownMenuItem(value: 'superuser', child: Text('Superuser (Admin)')),
                          ],
                          onChanged: (v) => setDialogState(() => selectedRole = v!),
                        ),
                        const SizedBox(height: 20),
                        const Text('Facility', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        DropdownButtonFormField<String>(
                          value: selectedFacility,
                          items: context.read<AdminProvider>().facilities.map((f) => DropdownMenuItem(value: f.id, child: Text(f.name))).toList(),
                          onChanged: (v) => setDialogState(() => selectedFacility = v!),
                        ),
                        const SizedBox(height: 20),
                        const Text('Assigned Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => setDialogState(() => showCategoryPanel = !showCategoryPanel),
                          icon: const Icon(Icons.category_outlined),
                          label: Text(selectedCategories.isEmpty ? 'Select Categories' : selectedCategories.join(', ')),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showCategoryPanel) ...[
                  const SizedBox(width: 20),
                  Container(
                    width: 350,
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey.shade300))),
                    child: FutureBuilder<List<String>>(
                      future: context.read<AdminProvider>().getCategories(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final categories = snapshot.data!;
                        return Column(
                          children: [
                            const Text('Available Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: ListView(
                                children: categories.map((cat) => CheckboxListTile(
                                  title: Text(cat),
                                  value: selectedCategories.contains(cat),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) selectedCategories.add(cat);
                                      else selectedCategories.remove(cat);
                                    });
                                  },
                                )).toList(),
                              ),
                            ),
                            ElevatedButton(onPressed: () => setDialogState(() => showCategoryPanel = false), child: const Text('OK')),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                if (user == null) {
                  await context.read<AdminProvider>().createUser(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                    nameController.text.trim(),
                    selectedRole,
                    selectedCategories,
                    selectedFacility,
                  );
                } else {
                  final updatedUser = UserModel(
                    uid: user.uid,
                    email: user.email,
                    name: nameController.text.trim(),
                    role: selectedRole,
                    assignedCategories: selectedCategories,
                    facilityId: selectedFacility,
                  );
                  await context.read<AdminProvider>().updateUserProfile(updatedUser);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('SAVE USER'),
            ),
          ],
        ),
      ),
    );
  }
}
