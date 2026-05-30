import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/count_provider.dart';
import '../../data/models/item_model.dart';
import '../../data/models/count_model.dart';

class PhotoAttachmentSheet extends StatefulWidget {
  final ItemMaster item;
  const PhotoAttachmentSheet({super.key, required this.item});

  @override
  State<PhotoAttachmentSheet> createState() => _PhotoAttachmentSheetState();
}

class _PhotoAttachmentSheetState extends State<PhotoAttachmentSheet> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final user = context.read<AuthProvider>().userModel!;
    final countProvider = context.read<CountProvider>();
    final itemCode = widget.item.itemCode;
    final existingDraft = countProvider.getDraft(itemCode);

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 50);
    if (photo == null) return;

    final updatedDraft = (existingDraft ?? CountModel(
      id: '',
      timestamp: DateTime.now(),
      userId: user.uid,
      category: widget.item.category,
      productCode: itemCode,
      facilityId: user.facilityId,
      quantities: CountQuantities(countCase: 0, countSubcase: 0, countPiece: 0),
      images: [],
      localImagePaths: [],
      isUploaded: false,
    )).copyWith(
      localImagePaths: [...(existingDraft?.localImagePaths ?? []), photo.path],
    );
    countProvider.updateDraftCount(itemCode, updatedDraft);
  }

  @override
  Widget build(BuildContext context) {
    final countProvider = context.watch<CountProvider>();
    final draft = countProvider.getDraft(widget.item.itemCode);
    final images = draft?.images ?? [];
    final localPaths = draft?.localImagePaths ?? [];
    final totalCount = images.length + localPaths.length;
    final profileUrl = draft?.profileImageUrl;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.itemName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('Photos ($totalCount / 5)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (totalCount == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.camera_enhance_outlined, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('No photos attached yet.', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ...images.map((url) => _buildImageThumbnail(url, isLocal: false, isProfile: profileUrl == url)),
                  ...localPaths.map((path) => _buildImageThumbnail(path, isLocal: true, isProfile: profileUrl == path)),
                ],
              ),
            ),
          const SizedBox(height: 32),
          if (totalCount < 5)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.add_a_photo),
                label: const Text('CAPTURE PHOTO'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(String source, {required bool isLocal, required bool isProfile}) {
    final countProvider = context.read<CountProvider>();
    final draft = countProvider.getDraft(widget.item.itemCode);
    
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 100,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isProfile ? Border.all(color: Colors.blue, width: 3) : Border.all(color: Colors.grey.shade200),
              image: DecorationImage(
                image: isLocal ? FileImage(File(source)) as ImageProvider : NetworkImage(source),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Actions Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      isProfile ? Icons.star : Icons.star_border, 
                      size: 18, 
                      color: isProfile ? Colors.yellow : Colors.white
                    ),
                    onPressed: () {
                      if (draft != null) {
                        countProvider.updateDraftCount(
                          widget.item.itemCode,
                          draft.copyWith(profileImageUrl: source),
                        );
                      }
                    },
                    tooltip: 'Set as Profile',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.white),
                    onPressed: () {
                      if (draft != null) {
                        final newImages = [...draft.images];
                        final newLocalPaths = [...draft.localImagePaths];
                        String? newProfileUrl = draft.profileImageUrl;

                        if (isLocal) newLocalPaths.remove(source);
                        else newImages.remove(source);

                        if (newProfileUrl == source) newProfileUrl = null;

                        countProvider.updateDraftCount(
                          widget.item.itemCode,
                          draft.copyWith(
                            images: newImages,
                            localImagePaths: newLocalPaths,
                            profileImageUrl: newProfileUrl,
                          ),
                        );
                      }
                    },
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ),
          ),
          if (isProfile)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('PROFILE', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}
