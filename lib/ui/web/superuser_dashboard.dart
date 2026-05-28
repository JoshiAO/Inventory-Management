import 'package:flutter/material.dart';
import 'user_management_page.dart';
import 'inventory_settings_page.dart';
import 'dashboard_summary_page.dart';

class SuperuserDashboard extends StatefulWidget {
  const SuperuserDashboard({super.key});

  @override
  State<SuperuserDashboard> createState() => _SuperuserDashboardState();
}

class _SuperuserDashboardState extends State<SuperuserDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardSummaryPage(),
    const UserManagementPage(),
    const InventorySettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
