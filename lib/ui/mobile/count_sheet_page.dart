import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/count_provider.dart';
import '../../data/models/item_model.dart';
import '../../data/models/count_model.dart';
import '../../core/app_theme.dart';
import 'photo_attachment_dialog.dart';
import 'upload_summary_page.dart';

class CountSheetPage extends StatefulWidget {
  const CountSheetPage({super.key});

  @override
  State<CountSheetPage> createState() => _CountSheetPageState();
}

class _CountSheetPageState extends State<CountSheetPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null && user.assignedCategories.isNotEmpty) {
        context.read<CountProvider>().loadItems(user.assignedCategories.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final countProvider = context.watch<CountProvider>();
    final user = authProvider.userModel!;

    return Scaffold(
      appBar: AppBar(
        title: Text('${user.assignedCategories.join(", ")} Count'),
        actions: [
          IconButton(
            icon: const Icon(Icons.password_rounded),
            onPressed: () => _showChangePasswordDialog(context, authProvider),
            tooltip: 'Change Password',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (v) => countProvider.updateSearch(v),
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: countProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: countProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = countProvider.items[index];
                      return ItemCountCard(item: item);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadSummaryPage()),
          );
        },
        child: const Icon(Icons.cloud_upload),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider authProvider) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your new password below.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              try {
                await authProvider.changePassword(passwordController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.errorColor),
                  );
                }
              }
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }
}

class ItemCountCard extends StatelessWidget {
  final ItemMaster item;
  const ItemCountCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SKU: ${item.itemCode}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.camera_alt_outlined, color: primaryColor),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => PhotoAttachmentDialog(item: item),
                    );
                  },
                  tooltip: 'Add Photo',
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(child: _QtyInput(label: 'CASES', item: item, type: 'case')),
                const SizedBox(width: 12),
                Expanded(child: _QtyInput(label: 'SUB-CASES', item: item, type: 'subcase')),
                const SizedBox(width: 12),
                Expanded(child: _QtyInput(label: 'PIECES', item: item, type: 'piece')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyInput extends StatelessWidget {
  final String label;
  final ItemMaster item;
  final String type; // 'case', 'subcase', 'piece'

  const _QtyInput({required this.label, required this.item, required this.type});

  @override
  Widget build(BuildContext context) {
    final countProvider = context.watch<CountProvider>();
    final draft = countProvider.getDraft(item.itemCode);
    
    int currentVal = 0;
    if (draft != null) {
      if (type == 'case') currentVal = draft.quantities.countCase;
      if (type == 'subcase') currentVal = draft.quantities.countSubcase;
      if (type == 'piece') currentVal = draft.quantities.countPiece;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: currentVal == 0 ? '' : currentVal.toString(),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            hintText: '0',
            fillColor: Colors.grey.shade50,
          ),
          onChanged: (value) {
            final int newVal = int.tryParse(value) ?? 0;
            final auth = context.read<AuthProvider>();
            
            final existingDraft = countProvider.getDraft(item.itemCode);
            
            int c = type == 'case' ? newVal : (existingDraft?.quantities.countCase ?? 0);
            int sc = type == 'subcase' ? newVal : (existingDraft?.quantities.countSubcase ?? 0);
            int p = type == 'piece' ? newVal : (existingDraft?.quantities.countPiece ?? 0);

            countProvider.updateDraftCount(
              item.itemCode,
              CountModel(
                id: existingDraft?.id ?? '',
                timestamp: DateTime.now(),
                userId: auth.userModel!.uid,
                category: item.category,
                productCode: item.itemCode,
                facilityId: auth.userModel!.facilityId,
                quantities: CountQuantities(countCase: c, countSubcase: sc, countPiece: p),
                images: existingDraft?.images ?? [],
                localImagePaths: [],
                isUploaded: false,
              ),
            );
          },
        ),
      ],
    );
  }
}
