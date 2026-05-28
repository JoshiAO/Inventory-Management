import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/count_provider.dart';
import '../../data/models/item_model.dart';
import '../../data/models/count_model.dart';

class PhotoAttachmentDialog extends StatefulWidget {
  final ItemModel item;
  const PhotoAttachmentDialog({super.key, required this.item});

  @override
  State<PhotoAttachmentDialog> createState() => _PhotoAttachmentDialogState();
}

class _PhotoAttachmentDialogState extends State<PhotoAttachmentDialog> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  Future<void> _takePhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final user = context.read<AuthProvider>().userModel!;
    final countProvider = context.read<CountProvider>();
    final itemCode = widget.item.itemCode;
    final category = widget.item.category;
    final existingDraft = countProvider.getDraft(itemCode);

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (photo == null) return;

    setState(() {
      _uploading = true;
    });

    try {
      final bytes = await photo.readAsBytes();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('inventory_photos/$itemCode/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final task = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await task.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final updatedDraft = CountModel(
        id: existingDraft?.id ?? '',
        timestamp: existingDraft?.timestamp ?? DateTime.now(),
        userId: user.uid,
        category: category,
        productCode: itemCode,
        quantities: existingDraft?.quantities ?? CountQuantities(countCase: 0, countSubcase: 0, countPiece: 0),
        images: [...(existingDraft?.images ?? []), downloadUrl],
        isUploaded: existingDraft?.isUploaded ?? false,
      );
      countProvider.updateDraftCount(itemCode, updatedDraft);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Photo attached successfully.')),
      );
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Upload failed: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final countProvider = context.watch<CountProvider>();
    final draft = countProvider.getDraft(widget.item.itemCode);
    final images = draft?.images ?? [];

    return AlertDialog(
      title: Text('Photos: ${widget.item.itemName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (images.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No photos attached (Max 5)'),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images.map((url) {
                return Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                        image: url.isNotEmpty
                            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                            : null,
                      ),
                      child: url.isEmpty ? const Icon(Icons.image, color: Colors.grey) : null,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: () {
                          final updatedImages = [...images]..remove(url);
                          final existingDraft = countProvider.getDraft(widget.item.itemCode);
                          if (existingDraft != null) {
                            countProvider.updateDraftCount(
                              widget.item.itemCode,
                              CountModel(
                                id: existingDraft.id,
                                timestamp: existingDraft.timestamp,
                                userId: existingDraft.userId,
                                category: existingDraft.category,
                                productCode: existingDraft.productCode,
                                quantities: existingDraft.quantities,
                                images: updatedImages,
                                isUploaded: existingDraft.isUploaded,
                              ),
                            );
                          }
                        },
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            if (images.length < 5)
              ElevatedButton.icon(
                onPressed: _uploading ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(_uploading ? 'Uploading...' : 'Take Photo'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
