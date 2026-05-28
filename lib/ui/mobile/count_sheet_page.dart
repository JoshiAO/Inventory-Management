import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/count_provider.dart';
import '../../data/models/item_model.dart';
import '../../data/models/count_model.dart';
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
      if (user != null) {
        context.read<CountProvider>().loadItems(user.assignedCategory);
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
        title: Text('${user.assignedCategory} Count'),
        actions: [
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
}

class ItemCountCard extends StatelessWidget {
  final ItemModel item;
  const ItemCountCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image_not_supported),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.blue),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => PhotoAttachmentDialog(item: item),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        item.itemCode,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QtyInput(label: 'Case', item: item, type: 'case'),
                _QtyInput(label: 'Subcase', item: item, type: 'subcase'),
                _QtyInput(label: 'Piece', item: item, type: 'piece'),
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
  final ItemModel item;
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
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          width: 80,
          child: TextFormField(
            initialValue: currentVal == 0 ? '' : currentVal.toString(),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.all(8),
            ),
            onChanged: (value) {
              final int newVal = int.tryParse(value) ?? 0;
              final auth = context.read<AuthProvider>();
              
              // Create or update draft
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
                  quantities: CountQuantities(countCase: c, countSubcase: sc, countPiece: p),
                  images: existingDraft?.images ?? [],
                  isUploaded: false,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
