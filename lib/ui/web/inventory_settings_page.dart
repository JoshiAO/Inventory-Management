import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/admin_provider.dart';
import '../../core/excel_service.dart';

class InventorySettingsPage extends StatefulWidget {
  const InventorySettingsPage({super.key});

  @override
  State<InventorySettingsPage> createState() => _InventorySettingsPageState();
}

class _InventorySettingsPageState extends State<InventorySettingsPage> {
  String? _selectedFacilityId;

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Inventory Settings'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GLOBAL DATA SECTION
            _buildSection(
              context,
              title: 'Global Data Management',
              subtitle: 'These settings affect the entire system regardless of the selected facility.',
              icon: Icons.public,
              color: Colors.blueGrey,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3,
                  children: [
                    _buildActionButton(
                      context,
                      title: 'Item Master',
                      subtitle: 'Update global product catalog',
                      icon: Icons.inventory_2_outlined,
                      onTap: () => _handleUpload(context, 'Item Master', isGlobal: true),
                    ),
                    _buildActionButton(
                      context,
                      title: 'Categories',
                      subtitle: 'Update item groupings',
                      icon: Icons.category_outlined,
                      onTap: () => _handleUpload(context, 'Categories', isGlobal: true),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 2. FACILITY DATA SECTION
            _buildSection(
              context,
              title: 'Facility-Specific Data',
              subtitle: 'Data uploaded here is private to the selected facility.',
              icon: Icons.business,
              color: primaryColor,
              children: [
                // Facility Selector prominently placed inside its section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 16),
                      const Text('Active Facility:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 24),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedFacilityId,
                            hint: const Text('Select a facility to manage its data...'),
                            isExpanded: true,
                            items: adminProvider.facilities.map((f) {
                              return DropdownMenuItem(value: f.id, child: Text(f.name));
                            }).toList(),
                            onChanged: (v) => setState(() => _selectedFacilityId = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3,
                  children: [
                    _buildActionButton(
                      context,
                      title: 'Price List',
                      subtitle: 'Upload facility pricing',
                      icon: Icons.payments_outlined,
                      isEnabled: _selectedFacilityId != null,
                      onTap: () => _handleUpload(context, 'Price List'),
                    ),
                    _buildActionButton(
                      context,
                      title: 'SSR Baseline',
                      subtitle: 'Upload target SSR targets',
                      icon: Icons.assignment_outlined,
                      isEnabled: _selectedFacilityId != null,
                      onTap: () => _handleUpload(context, 'SSR'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 3. MAINTENANCE / DANGER ZONE
            _buildSection(
              context,
              title: 'System Maintenance',
              subtitle: 'Caution: Actions in this section are permanent.',
              icon: Icons.settings_backup_restore,
              color: Colors.red,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3,
                  children: [
                    _buildActionButton(
                      context,
                      title: 'Clear Counts',
                      subtitle: 'Reset current cycle counts',
                      icon: Icons.delete_sweep_outlined,
                      color: Colors.orange,
                      isEnabled: _selectedFacilityId != null,
                      onTap: () => _confirmClear(context, 'counts', adminProvider.clearSystemData),
                    ),
                    _buildActionButton(
                      context,
                      title: 'Reset Catalog',
                      subtitle: 'Wipe Item Master & Prices',
                      icon: Icons.dangerous_outlined,
                      color: Colors.red,
                      onTap: () => _confirmClear(context, 'catalog', adminProvider.clearItemMaster),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color color,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
    bool isEnabled = true,
  }) {
    final themeColor = color ?? Theme.of(context).primaryColor;
    
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: themeColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUpload(BuildContext context, String type, {bool isGlobal = false}) async {
    if (!isGlobal && _selectedFacilityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a facility first.'), backgroundColor: Colors.orange),
      );
      return;
    }

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
        } else if (type == 'Price List') {
          data = ExcelService.parsePriceList(result.files.first.bytes!);
        } else if (type == 'Categories') {
          data = ExcelService.parseCategories(result.files.first.bytes!);
        } else {
          data = [];
        }

        await adminProvider.uploadInventoryData(type, data, facilityId: isGlobal ? null : _selectedFacilityId);
        
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

  void _confirmClear(BuildContext context, String type, Future<void> Function({String? facilityId}) action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear $type Data?'),
        content: Text('Are you sure you want to delete all $type records for the selected facility? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await action(facilityId: _selectedFacilityId);
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
