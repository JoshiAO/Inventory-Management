import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../../core/app_theme.dart';
import '../../core/discrepancy_service.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class DashboardSummaryPage extends StatefulWidget {
  const DashboardSummaryPage({super.key});

  @override
  State<DashboardSummaryPage> createState() => _DashboardSummaryPageState();
}

class _DashboardSummaryPageState extends State<DashboardSummaryPage> {
  String? _selectedFacilityId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userModel;
      if (user != null) {
        setState(() => _selectedFacilityId = user.facilityId);
        context.read<DashboardProvider>().loadMetrics(user.facilityId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final dashboardProvider = context.watch<DashboardProvider>();
    final adminProvider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Inventory Overview'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: ElevatedButton.icon(
              onPressed: () {
                if (_selectedFacilityId != null) {
                  _exportActualCountReport(context, _selectedFacilityId!);
                }
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('EXPORT REPORT (XLSX)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Facility Context:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                SizedBox(
                  width: 300,
                  child: DropdownButtonFormField<String>(
                    value: _selectedFacilityId,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(),
                    ),
                    items: adminProvider.facilities.map((f) {
                      return DropdownMenuItem(value: f.id, child: Text(f.name));
                    }).toList(),
                    onChanged: (v) {
                      setState(() => _selectedFacilityId = v);
                      if (v != null) {
                        context.read<DashboardProvider>().loadMetrics(v);
                      }
                    },
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    if (_selectedFacilityId != null) {
                      context.read<DashboardProvider>().loadMetrics(_selectedFacilityId!);
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Metrics',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: dashboardProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Key Metrics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildSummaryCard('Total Items', dashboardProvider.totalItems.toString(), Icons.inventory_2_outlined, primaryColor)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildSummaryCard('Discrepancies', dashboardProvider.discrepanciesCount.toString(), Icons.warning_amber_rounded, AppTheme.warningColor)),
                            const SizedBox(width: 20),
                            Expanded(child: _buildSummaryCard('Active Counts', dashboardProvider.activeCounts.toString(), Icons.timer_outlined, Colors.deepPurple)),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildChartCard(
                                'Discrepancy by Category (PHP ₱)',
                                _CategoryDiscrepancyChart(data: dashboardProvider.categoryDiscrepancies),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: _buildChartCard(
                                'Count Completion Status',
                                _CountStatusPieChart(
                                  statusCounts: dashboardProvider.statusCounts,
                                  totalItems: dashboardProvider.totalItems,
                                  itemsPending: dashboardProvider.itemsPending,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportActualCountReport(BuildContext context, String facilityId) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Generating Actual Count XLSX...'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final savedLocation = await DiscrepancyService().exportActualCountReport(facilityId);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Actual Count XLSX saved: $savedLocation'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Export failed: $error'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(height: 320, child: chart),
          ],
        ),
      ),
    );
  }
}

class _CategoryDiscrepancyChart extends StatelessWidget {
  final Map<String, double> data;
  const _CategoryDiscrepancyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No discrepancy data for this facility.', style: TextStyle(color: Colors.grey)));
    }

    final categories = data.keys.toList();
    final values = data.values.toList();
    final maxVal = values.isNotEmpty ? values.reduce(max) : 1.0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
        barGroups: List.generate(categories.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: values[index],
                color: Theme.of(context).primaryColor,
                width: 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              )
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= categories.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    categories[index],
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) => Text('₱${value.toInt()}', style: const TextStyle(fontSize: 10)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _CountStatusPieChart extends StatelessWidget {
  final Map<String, int> statusCounts;
  final int totalItems;
  final int itemsPending;

  const _CountStatusPieChart({
    required this.statusCounts,
    required this.totalItems,
    required this.itemsPending,
  });

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) {
      return const Center(child: Text('No item catalog loaded.', style: TextStyle(color: Colors.grey)));
    }

    final balanced = statusCounts['Balanced'] ?? 0;
    final over = statusCounts['Over'] ?? 0;
    final short = statusCounts['Short'] ?? 0;

    return Column(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: [
                if (balanced > 0)
                  PieChartSectionData(
                    color: AppTheme.successColor,
                    value: balanced.toDouble(),
                    title: 'Balanced',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                if (over > 0)
                  PieChartSectionData(
                    color: Colors.blue,
                    value: over.toDouble(),
                    title: 'Over',
                    radius: 55,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                if (short > 0)
                  PieChartSectionData(
                    color: AppTheme.errorColor,
                    value: short.toDouble(),
                    title: 'Short',
                    radius: 55,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                if (itemsPending > 0)
                  PieChartSectionData(
                    color: Colors.grey.shade300,
                    value: itemsPending.toDouble(),
                    title: 'Pending',
                    radius: 45,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _buildLegendItem('Balanced', AppTheme.successColor),
            _buildLegendItem('Over', Colors.blue),
            _buildLegendItem('Short', AppTheme.errorColor),
            _buildLegendItem('Pending', Colors.grey.shade300),
          ],
        )
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
