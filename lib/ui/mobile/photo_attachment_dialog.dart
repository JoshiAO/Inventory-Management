import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/count_provider.dart';
import '../../data/models/item_model.dart';
import '../../data/models/count_model.dart';

class PhotoAttachmentDialog extends StatefulWidget {
  final ItemMaster item;
  const PhotoAttachmentDialog({super.key, required this.item});

  @override
  State<PhotoAttachmentDialog> createState() => _PhotoAttachmentDialogState();
}

class _PhotoAttachmentDialogState extends State<PhotoAttachmentDialog> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final user = context.read<AuthProvider>().userModel!;
    final countProvider = context.read<CountProvider>();
    final itemCode = widget.item.itemCode;
    final existingDraft = countProvider.getDraft(itemCode);

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50); // Compression here
    if (photo == null) return;

    final updatedDraft = CountModel(
      id: existingDraft?.id ?? '',
      timestamp: existingDraft?.timestamp ?? DateTime.now(),
      userId: user.uid,
      category: widget.item.category,
      productCode: itemCode,
      facilityId: user.facilityId,
      quantities: existingDraft?.quantities ?? CountQuantities(countCase: 0, countSubcase: 0, countPiece: 0),
      images: existingDraft?.images ?? [],
      localImagePaths: [...(existingDraft?.localImagePaths ?? []), photo.path],
      isUploaded: existingDraft?.isUploaded ?? false,
    );
    countProvider.updateDraftCount(itemCode, updatedDraft);
  }

  @override
  Widget build(BuildContext context) {
    final countProvider = context.watch<CountProvider>();
    final draft = countProvider.getDraft(widget.item.itemCode);
    final images = draft?.images ?? [];
    final localPaths = draft?.localImagePaths ?? [];

    return AlertDialog(
      title: Text('Photos: ${widget.item.itemName}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (images.isEmpty && localPaths.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('No photos attached (Max 5)'),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...images.map((url) => _buildImageWidget(url, isLocal: false)),
                ...localPaths.map((path) => _buildImageWidget(path, isLocal: true)),
              ],
            ),
            const SizedBox(height: 20),
            if ((images.length + localPaths.length) < 5)
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
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

  Widget _buildImageWidget(String source, {required bool isLocal}) {
    final countProvider = context.read<CountProvider>();
    
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
            image: DecorationImage(
              image: isLocal ? FileImage(File(source)) as ImageProvider : NetworkImage(source),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          child: GestureDetector(
            onTap: () {
              final existingDraft = countProvider.getDraft(widget.item.itemCode);
              if (existingDraft != null) {
                final newImages = [...existingDraft.images];
                final newLocalPaths = [...existingDraft.localImagePaths];
                
                if (isLocal) newLocalPaths.remove(source);
                else newImages.remove(source);

                countProvider.updateDraftCount(
                  widget.item.itemCode,
                  CountModel(
                    id: existingDraft.id,
                    timestamp: existingDraft.timestamp,
                    userId: existingDraft.userId,
                    category: existingDraft.category,
                    productCode: existingDraft.productCode,
                    facilityId: existingDraft.facilityId,
                    quantities: existingDraft.quantities,
                    images: newImages,
                    localImagePaths: newLocalPaths,
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
  }
}
