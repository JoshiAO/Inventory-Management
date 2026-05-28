import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/admin_provider.dart';
import '../../core/excel_service.dart';

class InventorySettingsPage extends StatelessWidget {
  const InventorySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Data Uploads', Icons.cloud_upload),
            const SizedBox(height: 16),
            _buildUploadCard(
              context,
              'Item Master',
              'Update the catalog of all items and codes.',
              () => _handleUpload(context, 'Item Master'),
            ),
            _buildUploadCard(
              context,
              'Price List',
              'Update pricing reference for discrepancy value calculation.',
              () => _handleUpload(context, 'Price List'),
            ),
            _buildUploadCard(
              context,
              'SSR Baseline',
              'Update the Stock Status Report for current inventory targets.',
              () => _handleUpload(context, 'SSR'),
            ),
            const SizedBox(height: 48),
            _buildSectionHeader(context, 'Danger Zone', Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              'Clear Uploaded Counts',
              'This will permanently delete all user-uploaded counts and reset the current inventory cycle.',
              Colors.orange,
              () => _confirmClear(context, 'counts', adminProvider.clearSystemData),
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              'Reset Item Master & Prices',
              'This will wipe the entire item catalog and pricing data. Use with extreme caution.',
              Colors.red,
              () => _confirmClear(context, 'catalog', adminProvider.clearItemMaster),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildUploadCard(BuildContext context, String title, String subtitle, VoidCallback onTap) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, Color color, VoidCallback onTap) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withAlpha(128), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.delete_forever, color: color),
        onTap: onTap,
      ),
    );
  }

  void _handleUpload(BuildContext context, String type) async {
    final adminProvider = context.read<AdminProvider>();
    
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );

    if (result != null && result.files.first.bytes != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Processing $type...')),
        );
      }

      try {
        List<Map<String, dynamic>> data;
        if (type == 'Item Master') {
          data = ExcelService.parseItemMaster(result.files.first.bytes!);
        } else if (type == 'SSR') {
          data = ExcelService.parseSSR(result.files.first.bytes!);
        } else {
          data = ExcelService.parseItemMaster(result.files.first.bytes!);
        }

        await adminProvider.uploadInventoryData(type, data);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$type uploaded successfully (${data.length} records).')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _confirmClear(BuildContext context, String type, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear $type Data?'),
        content: Text('Are you sure you want to delete all $type records? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await action();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$type data cleared successfully.')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
