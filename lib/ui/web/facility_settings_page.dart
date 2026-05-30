import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/admin_provider.dart';
import '../../core/excel_service.dart';
import '../../core/migration_service.dart';
import '../../data/models/facility_model.dart';

class FacilitySettingsPage extends StatelessWidget {
  const FacilitySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Facility Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Manage Facilities', Icons.business),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddFacilityDialog(context),
              child: const Text('ADD NEW FACILITY'),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              itemCount: adminProvider.facilities.length,
              itemBuilder: (context, index) {
                final facility = adminProvider.facilities[index];
                return Card(
                  child: ListTile(
                    title: Text(facility.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(facility.location),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showFacilityActions(context, facility),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showAddFacilityDialog(BuildContext context) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Facility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Facility Name')),
            TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              context.read<AdminProvider>().addFacility(nameController.text, locationController.text);
              Navigator.pop(context);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _showFacilityActions(BuildContext context, Facility facility) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Manage ${facility.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Upload Price List'),
              onTap: () => _handleUpload(context, 'Price List', facility.id),
            ),
            ListTile(
              title: const Text('Upload SSR Baseline'),
              onTap: () => _handleUpload(context, 'SSR', facility.id),
            ),
            ListTile(
              title: const Text('Migrate Existing Data to Facility'),
              onTap: () async {
                await MigrationService().migrateToFacility(facility.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Migration for ${facility.name} complete.')),
                  );
                }
              },
            ),
            ListTile(
              title: const Text('Clear Facility Data'),
              tileColor: Colors.red.withOpacity(0.1),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Clear Data'),
                    content: const Text('This will delete all counts, prices, and SSR baseline data for this facility. Are you sure?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                      TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('CLEAR')),
                    ],
                  ),
                );
                
                if (confirm == true && context.mounted) {
                  await context.read<AdminProvider>().clearSystemData(facilityId: facility.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Data cleared for ${facility.name}.')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleUpload(BuildContext context, String type, String facilityId) async {
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
        if (type == 'SSR') {
          data = ExcelService.parseSSR(result.files.first.bytes!);
        } else if (type == 'Price List') {
          data = ExcelService.parsePriceList(result.files.first.bytes!);
        } else {
          data = [];
        }

        await adminProvider.uploadInventoryData(type, data, facilityId: facilityId);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$type uploaded successfully for facility (${data.length} records).')),
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
}
