import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/app_theme.dart';
import 'user_management_page.dart';
import 'inventory_settings_page.dart';
import 'facility_settings_page.dart';
import 'dashboard_summary_page.dart';
import 'item_manager_page.dart';

class SuperuserDashboard extends StatefulWidget {
  const SuperuserDashboard({super.key});

  @override
  State<SuperuserDashboard> createState() => _SuperuserDashboardState();
}

class _SuperuserDashboardState extends State<SuperuserDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardSummaryPage(),
    const ItemManagerPage(),
    const UserManagementPage(),
    const InventorySettingsPage(),
    const FacilitySettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.inventory_2, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'ADMIN PANEL',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _SidebarItem(
                        icon: Icons.dashboard_outlined,
                        label: 'Dashboard Summary',
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      _SidebarItem(
                        icon: Icons.inventory_2_outlined,
                        label: 'Item Manager',
                        isSelected: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                      _SidebarItem(
                        icon: Icons.people_outline,
                        label: 'User Management',
                        isSelected: _selectedIndex == 2,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                      _SidebarItem(
                        icon: Icons.settings_outlined,
                        label: 'Inventory Settings',
                        isSelected: _selectedIndex == 3,
                        onTap: () => setState(() => _selectedIndex = 3),
                      ),
                      _SidebarItem(
                        icon: Icons.business_outlined,
                        label: 'Facility Settings',
                        isSelected: _selectedIndex == 4,
                        onTap: () => setState(() => _selectedIndex = 4),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _SidebarItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    isSelected: false,
                    onTap: () => context.read<AuthProvider>().logout(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade50,
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: isSelected ? primaryColor : Colors.grey.shade600,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? primaryColor : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
      ),
    );
  }
}
