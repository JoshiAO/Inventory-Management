import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/count_provider.dart';

class UploadSummaryPage extends StatelessWidget {
  const UploadSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final countProvider = context.watch<CountProvider>();
    final drafts = countProvider.items.where((item) => countProvider.getDraft(item.itemCode) != null).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Review & Upload')),
      body: Column(
        children: [
          Expanded(
            child: drafts.isEmpty
                ? const Center(child: Text('No items counted yet.'))
                : ListView.builder(
                    itemCount: drafts.length,
                    itemBuilder: (context, index) {
                      final item = drafts[index];
                      final draft = countProvider.getDraft(item.itemCode)!;
                      return ListTile(
                        title: Text(item.itemName),
                        subtitle: Text(
                          'C: ${draft.quantities.countCase} | SC: ${draft.quantities.countSubcase} | P: ${draft.quantities.countPiece}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (draft.images.isNotEmpty)
                              const Icon(Icons.camera_alt, color: Colors.green),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle, color: Colors.blue),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: drafts.isEmpty || countProvider.isLoading
                  ? null
                  : () async {
                      await countProvider.uploadCounts();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Upload successful!')),
                        );
                        Navigator.pop(context);
                      }
                    },
              child: countProvider.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('UPLOAD ALL TO FIRESTORE'),
            ),
          ),
        ],
      ),
    );
  }
}
